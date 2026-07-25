import os
import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Literal, List
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler

# 1. Load the saved model, scaler, and feature column order

MODEL_DIR = os.path.join(os.path.dirname(__file__), "model")
DATA_PATH = os.path.join(os.path.dirname(__file__), "data", "imihigo_district_scores.csv")

model = joblib.load(os.path.join(MODEL_DIR, "best_model.joblib"))
scaler = joblib.load(os.path.join(MODEL_DIR, "scaler.joblib"))
feature_cols = joblib.load(os.path.join(MODEL_DIR, "feature_cols.joblib"))

PROVINCES = ["Eastern", "Kigali", "Northern", "Southern", "Western"]

# 2. Create the FastAPI app

app = FastAPI(
    title="PAP - District Imihigo Score Prediction",
    description="Predicts a district's Imihigo score.",
    version="1.0.0",
)

# 3. CORS 

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://localhost:\d+",
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)
 
# 4. Request/response schema

class PredictionRequest(BaseModel):
    prior_score: float = Field(
        ..., ge=0, le=100,
        description="District's most recent known Imihigo score (%)"
    )
    year_number: int = Field(
        ..., ge=0, le=10,
        description="Years since the first year in training data (0 = earliest year, e.g. 2021/2022)"
    )
    province: Literal["Eastern", "Kigali", "Northern", "Southern", "Western"] = Field(
        ..., description="District's province"
    )


class PredictionResponse(BaseModel):
    predicted_score: float


class NewRecord(BaseModel):
    district: str
    province: Literal["Eastern", "Kigali", "Northern", "Southern", "Western"]
    fiscal_year: str = Field(..., description="e.g. '2025/2026'")
    overall_score_pct: float = Field(..., ge=0, le=100)


class RetrainRequest(BaseModel):
    new_records: List[NewRecord]


class RetrainResponse(BaseModel):
    message: str
    rows_used_for_training: int



# 5. status endpoint

@app.get("/")
def status():
    return {"message": "PAP - District Imihigo Score Prediction API is running."}



# 6. Prediction endpoint

@app.post("/predict", response_model=PredictionResponse)
def predict(request: PredictionRequest):
    
    row = {col: 0.0 for col in feature_cols}
    row["prior_score"] = request.prior_score
    row["year_number"] = request.year_number

    province_col = f"province_{request.province}"
    if province_col in row:
        row[province_col] = 1.0

    input_df = pd.DataFrame([row])[feature_cols]
    input_scaled = scaler.transform(input_df)
    prediction = model.predict(input_scaled)[0]

    return PredictionResponse(predicted_score=round(float(prediction), 2))


# 7. Retraining endpoint


@app.post("/retrain", response_model=RetrainResponse)
def retrain(request: RetrainRequest):
    if len(request.new_records) == 0:
        raise HTTPException(status_code=400, detail="No new records provided.")

    # Load existing data and append the new rows
    existing_df = pd.read_csv(DATA_PATH)
    new_rows_df = pd.DataFrame([r.dict() for r in request.new_records])
    combined_df = pd.concat([existing_df, new_rows_df], ignore_index=True)
    combined_df.to_csv(DATA_PATH, index=False)

    # Rebuild features exactly as done in the training notebook
    work = combined_df.copy()
    work["fiscal_year_start"] = work["fiscal_year"].str.slice(0, 4).astype(int)
    work = work.sort_values(["district", "fiscal_year_start"])
    work["prior_score"] = work.groupby("district")["overall_score_pct"].shift(1)

    model_df = work.dropna(subset=["prior_score"]).copy()
    model_df["year_number"] = model_df["fiscal_year_start"] - model_df["fiscal_year_start"].min()
    model_df = pd.get_dummies(model_df, columns=["province"])

    # Make sure all expected province columns exist
    for col in feature_cols:
        if col.startswith("province_") and col not in model_df.columns:
            model_df[col] = 0.0

    X = model_df[feature_cols]
    y = model_df["overall_score_pct"]

    new_scaler = StandardScaler()
    X_scaled = new_scaler.fit_transform(X)

    new_model = RandomForestRegressor(n_estimators=100, max_depth=4, random_state=42)
    new_model.fit(X_scaled, y)

    # Overwrite the saved model files with the newly retrained version
    joblib.dump(new_model, os.path.join(MODEL_DIR, "best_model.joblib"))
    joblib.dump(new_scaler, os.path.join(MODEL_DIR, "scaler.joblib"))

    # Update the in-memory model so /predict immediately uses the new version
    global model, scaler
    model = new_model
    scaler = new_scaler

    return RetrainResponse(
        message="Model retrained successfully with new data.",
        rows_used_for_training=len(X),
    )
