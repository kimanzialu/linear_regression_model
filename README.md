PAP - District Imihigo Score Prediction 

My Mission:

My mission is to apply my coding skills to develop technologies that empower Rwandan citizens to track their elected officials and make governance more transparent across Rwanda. The model I created in this assignment predicts a district's Imihigo (perfomance contracts signed by local leaders across Rwanda to ensure accountability) score.

The data source:

NISR (National Institute of Statistics of Rwanda) annual Imihigo Evaluation Reports in 2019/2020, 2021/2022, 2022/2023, 2023/2024, and 2024/2025, for all Rwanda's 27 districts plus the City of Kigali.

API:

Public endpoint (Swagger UI): https://linear-regression-model-s8me.onrender.com/docs


Video demo:

YouTube link: TODO

Running the mobile app:

This Flutter app that predicts a district's Imihigo score
by calling the API I created.

a. How to run it:

_cd summative/FlutterApp

flutter pub get

flutter run_


b. How to use it:

1. Pick a district from the District dropdown (this auto-fills its most
   recent known score and province using real NISR data)
2. If needed, one can adjust the Prior Year Score when testing a certain scenario
3. Enter a Year Number (0 = 2021/2022, 1 = 2022/2023, 2 = 2023/2024,
   3 = 2024/2025, 4 = 2025/2026, ...)
4. Click _Predict_ to get the model's predicted score
