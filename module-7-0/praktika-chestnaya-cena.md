# Практическое занятие. Честная цена

**Цель:** за 4 академических часа на таблице квартир поймать модель, которая «угадывает» цену из подписи, сравнить её с двумя простыми правилами и с лесом, проверить победителя по складкам и выдать прогноз для трёх новых квартир.

**Опора:** страницы блока 7, файл [flats_gaps.csv](data/flats_gaps.csv) (`module-7-0/data/flats_gaps.csv` в ноутбуке). Окружение `.venv`, ядро Jupyter — `./.venv/Scripts/python.exe`. Рабочая папка — корень курса. Цена в тысячах рублей. Один академический час — 45 минут.

К концу занятия у пары на руках три числа MAE (подпись, среднее, лес), таблица ошибки по районам и три прогноза. Новых алгоритмов нет: те же `Pipeline`, лес и пять складок.

| Час | Что происходит |
|-----|----------------|
| 1 | Находят утечку в подписи цены |
| 2 | Считают среднее и среднее района, сравнивают с лесом |
| 3 | Проверяют лес пятью складками и смотрят, где он врёт |
| 4 | Считают цену трёх новых квартир и коротко докладывают |

---

## Подготовка

```powershell
.\.venv\Scripts\Activate.ps1
python -m pip install pandas scikit-learn
```

Ноутбук `module-7-0/lab-chestnaya-cena.ipynb`, ядро `.venv`. Первая ячейка — markdown: ФИО, дата, заголовок «Честная цена».

---

## Час 1. Слишком хороший прогноз

В файле рядом с ценой лежит столбец `price_note`. В нём текст вида `цена 6230`. Если вытащить из текста число и отдать его модели, она не предсказывает цену, а читает ответ. На проверке ошибка почти нулевая. В жизни у новой квартиры такой подписи ещё нет.

**Ячейка:**

```python
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline

flats = pd.read_csv("module-7-0/data/flats_gaps.csv")
print(flats[["price", "price_note"]].head(3))

# Из текста «цена 6230» достаём 6230. Это и есть утечка: число уже равно цели.
flats["note_price"] = flats["price_note"].str.extract(r"(\d+)").astype(float)
print((flats["note_price"] == flats["price"]).all())

y = flats.price
X_leak = flats[["area", "year", "rooms", "district", "note_price"]]
X_train, X_valid, y_train, y_valid = train_test_split(
    X_leak, y, train_size=0.8, test_size=0.2, random_state=0
)

leak_prep = ColumnTransformer(
    transformers=[
        ("num", SimpleImputer(strategy="constant"), ["area", "year", "rooms", "note_price"]),
        ("cat", Pipeline(steps=[
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("onehot", OneHotEncoder(handle_unknown="ignore")),
        ]), ["district"]),
    ]
)
leak_model = Pipeline(steps=[
    ("preprocessor", leak_prep),
    ("model", RandomForestRegressor(n_estimators=30, random_state=0)),
])
leak_model.fit(X_train, y_train)
mae_leak = mean_absolute_error(y_valid, leak_model.predict(X_valid))
print(f"MAE с подписью цены: {mae_leak:.2f}")
```

**Критерий часа 1.** Сравнение `note_price` и `price` печатает `True`: подпись повторяет ответ во всех 10000 строках. MAE с подписью — **0.76**. Это не качество модели. Дальше столбец `note_price` не используют.

---

## Час 2. Простое правило и лес

Честная модель видит только площадь, год, комнаты и район. Прежде чем радоваться лесу, ставят две планки, которые считаются без деревьев.

1. Всем квартирам проверки записать среднюю цену обучения.
2. Записать среднюю цену своего района на обучении. Если район пустой, остаётся общая средняя: для слова «нет» отдельного среднего на обучении не было.

**Ячейка:**

```python
X = flats[["area", "year", "rooms", "district"]]
X_train, X_valid, y_train, y_valid = train_test_split(
    X, y, train_size=0.8, test_size=0.2, random_state=0
)

# Одна и та же цена для всех 2000 строк проверки. Это пол, ниже которого лес обязан быть.
mean_price = float(y_train.mean())
pred_mean = np.full(shape=len(y_valid), fill_value=mean_price)
mae_mean = mean_absolute_error(y_valid, pred_mean)
print(f"Средняя цена обучения: {mean_price:.2f}")
print(f"MAE общей средней: {mae_mean:.2f}")

# groupby считает среднее только по обучению. map переносит его на проверку по названию района.
district_mean = y_train.groupby(X_train["district"]).mean()
print(district_mean.round(2))
pred_district = X_valid["district"].map(district_mean).fillna(mean_price)
mae_district = mean_absolute_error(y_valid, pred_district)
print(f"MAE средней по району: {mae_district:.2f}")
```

**Ячейка. Лес в конвейере.**

```python
prep = ColumnTransformer(
    transformers=[
        ("num", SimpleImputer(strategy="constant"), ["area", "year", "rooms"]),
        ("cat", Pipeline(steps=[
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("onehot", OneHotEncoder(handle_unknown="ignore")),
        ]), ["district"]),
    ]
)
forest = Pipeline(steps=[
    ("preprocessor", prep),
    ("model", RandomForestRegressor(n_estimators=30, random_state=0)),
])
# fit на сырой таблице: пустые годы и слова районов конвейер закрывает сам.
forest.fit(X_train, y_train)
pred_forest = forest.predict(X_valid)
mae_forest = mean_absolute_error(y_valid, pred_forest)
print(f"MAE леса: {mae_forest:.2f}")
```

**Критерий часа 2.** Средняя цена обучения — **6724.52**. MAE общей средней — **1798.36**. Средние районов: восток 6354.96, запад 6663.40, север 6568.65, центр 7322.50, юг 6717.01. MAE средней по району — **1784.91**: район почти ничего не добавляет, если внутри него не смотреть на площадь и год. MAE леса — **129.81**.

---

## Час 3. Складки и слабое место

Одна проверка из 2000 строк могла оказаться удачной. Пять складок учат лес заново на каждой четвёрке частей. Отдельно смотрят средний промах по районам на той же проверке, что в часе 2. Пустой район подписан словом `нет`.

**Ячейка:**

```python
scores = -1 * cross_val_score(
    forest, X, y, cv=5, scoring="neg_mean_absolute_error"
)
print("MAE по складкам:", [f"{float(s):.2f}" for s in scores])
print(f"Средняя MAE складок: {float(scores.mean()):.2f}")

report = X_valid.copy()
report["miss"] = (pred_forest - y_valid.to_numpy()).abs()
# fillna только для подписи группы. В модель это слово уже не отправляется.
by_district = report.groupby(report["district"].fillna("нет"))["miss"].mean()
print(by_district.round(2))
```

**Критерий часа 3.** Складки: **128.21, 129.47, 128.42, 130.08, 128.96**. Среднее — **129.03**. Победа леса над средней 1798 не зависит от одного жребия. Промах по районам на проверке: восток 122.01, запад 123.74, север 119.54, центр 132.51, юг 124.45, пустой район **352.26**. Слабое место — квартиры без района: их 47 на проверке, и конвейер подставляет им самый частый район, которого у квартиры не было.

---

## Час 4. Три новые квартиры

Новых строк нет в файле, цены у них нет и подписи `price_note` нет. Конвейер уже обучен на честных столбцах. У третьей квартиры год неизвестен: так же, как у части старых строк, его закроет `SimpleImputer` внутри `predict`.

**Ячейка:**

```python
new_flats = pd.DataFrame([
    {"area": 45, "year": 1988, "rooms": 2, "district": "север"},
    {"area": 88, "year": 2015, "rooms": 3, "district": "юг"},
    {"area": 70, "year": np.nan, "rooms": 3, "district": "центр"},
])
forecast = forest.predict(new_flats)
for row, price in zip(new_flats.to_dict(orient="records"), forecast):
    print(row, f"прогноз {price:.2f}")
new_flats["forecast"] = forecast.round(2)
new_flats.to_csv("module-7-0/data/new_forecast.csv", index=False)
```

**Критерий часа 4.** Прогнозы: север 45 м² — **4096.43**, юг 88 м² — **8104.47**, центр без года — **6997.34**. Файл `module-7-0/data/new_forecast.csv` содержит эти три строки и ни одной настоящей цены.

Доклад пары, полстраницы:

1. MAE с подписью 0.76 — почему это не победа.
2. Три честные MAE: 1798.36, 1784.91, 129.81.
3. Где лес слабее всего (пустой район, 352.26) и три прогноза.

| Симптом | Что проверить |
|---------|----------------|
| MAE с подписью около 129, а не 0.76 | В конвейер не попал столбец `note_price` |
| MAE леса не 129.81 | Другое `n_estimators`, другой `random_state` или в признаки снова попала подпись |
| У пустого района нет отдельной строки | Перед `groupby` район заполняют словом `нет` только в отчёте |
| Прогноз центра около 4000 | В третьей строке район `центр`, год пустой, площадь 70, а не 45 |
| `FileNotFoundError` | Путь `module-7-0/data/flats_gaps.csv` от корня курса |
