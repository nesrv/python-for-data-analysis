# 9. Интерфейсы, препроцессинг и три задачи

**Цель:** закрыть пункты программы 6.2–6.6, которых нет в занятиях 6.0 и в блоке 7. Увидеть разницу между `transform` и `predict`, масштабировать числа, сравнить линейную регрессию с лесом, классифицировать заявку на карту и разложить квартиры на кластеры без цены.

**Опора:** файл квартир `module-7-0/data/flats_gaps.csv` и заявки `module-7-0/data/AER_credit_card_data.csv`. Окружение `.venv`, ядро Jupyter — `./.venv/Scripts/python.exe`. Рабочая папка — корень курса. Цена квартиры в тысячах рублей.

В блоке 7 модель почти всегда случайный лес. Здесь к лесу добавляются три других инструмента sklearn: линейная регрессия, логистическая регрессия и `KMeans`. Общий для них приём — подготовка таблицы отдельным объектом, а не руками перед `fit`.

| Пункт программы | Раздел здесь | Что появляется впервые |
|-----------------|--------------|------------------------|
| 6.2 Интерфейсы | 9.1 | `fit`, `transform`, `predict`, `score` |
| 6.3 Препроцессинг | 9.2 | `StandardScaler`, матрица после `transform` |
| 6.4 Регрессия | 9.3 | `LinearRegression` рядом с лесом |
| 6.5 Классификация | 9.4 | `LogisticRegression` и матрица ошибок |
| 6.6 Кластеризация | 9.5 | `KMeans` без столбца цены |

---

## Подготовка

```powershell
.\.venv\Scripts\Activate.ps1
python -m pip install pandas scikit-learn
```

Ноутбук `module-9/lab9-tri-zadachi.ipynb`, ядро `.venv`. Первая ячейка — markdown: ФИО, дата, заголовок «9. Интерфейсы, препроцессинг и три задачи».

---

## 9.1. Интерфейсы fit, transform, predict, score

У объектов sklearn два разных контракта, и их легко перепутать.

Преобразователь готовит таблицу. У него есть `fit` и `transform`. `fit` запоминает правило по обучению: среднее для пропуска, среднее и разброс для масштаба, список районов для кодирования. `transform` применяет уже запомненное правило и к обучению, и к проверке. `predict` у преобразователя нет: он не выдаёт цену.

Оценщик отвечает на вопрос. У него есть `fit` и `predict`. `fit` подбирает модель по строкам, где ответ известен. `predict` выдаёт ответ для новых строк. `score` — одна сводная цифра качества. Для регрессии это не MAE, а доля объяснённого разброса, её называют R². Ближе к 1 — модель повторяет колебания цены. Ноль — она не лучше, чем просто назвать среднюю.

`fit_transform` — это `fit` и сразу `transform` на той же таблице. Его вызывают на обучении. На проверке только `transform`: иначе правило пересчитается по проверке, и это уже утечка из блока 7.

**Ячейка:**

```python
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import mean_absolute_error, accuracy_score, confusion_matrix
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.cluster import KMeans

flats = pd.read_csv("module-7-0/data/flats_gaps.csv")
y = flats.price
# Подпись цены и номер квартиры в признаки не входят: это не свойства квартиры на момент прогноза.
X = flats[["area", "year", "rooms", "district"]]
X_train, X_valid, y_train, y_valid = train_test_split(
    X, y, train_size=0.8, test_size=0.2, random_state=0
)

num_cols = ["area", "year", "rooms"]
# SimpleImputer — преобразователь. fit запоминает среднее по каждому столбцу обучения.
imputer = SimpleImputer()
imputer.fit(X_train[num_cols])
print("Средние, которые запомнил imputer:", np.round(imputer.statistics_, 2))
# transform заполняет проверку этими средними. Своё среднее проверки здесь не считается.
filled_valid = imputer.transform(X_valid[num_cols])
print("Пустых ячеек после transform:", int(np.isnan(filled_valid).sum()))
# predict у преобразователя нет. hasattr проверяет это, не вызывая ошибку.
print("Есть predict у imputer:", hasattr(imputer, "predict"))
print("Есть transform у imputer:", hasattr(imputer, "transform"))
```

**Критерий 9.1.** После `transform` пустых ячеек 0. У `SimpleImputer` нет метода `predict`, метод `transform` есть. Печать `hasattr` даёт `False`, затем `True`. Средние imputer — три числа, по одному на площадь, год и комнаты. Их не сверяют поцифренно: дальше важно не само среднее, а то, что оно посчитано только по обучению.

---

## 9.2. Препроцессинг: масштаб и район в одной матрице

Линейная модель и кластеры смотрят на расстояния между числами. Площадь живёт в диапазоне десятков, год — около 2000. Без масштаба год перетянет расстояние на себя. `StandardScaler` вычитает среднее столбца и делит на его разброс. После этого у столбца на обучении среднее 0 и разброс 1.

Район по-прежнему текст. Его нельзя вычесть и поделить. Ветка для района другая: самый частый район вместо пустой ячейки, затем столбец из 0 и 1 на каждый район. `ColumnTransformer` склеивает обе ветки в одну матрицу. Модель дальше видит только числа.

**Ячейка:**

```python
prep = ColumnTransformer(
    transformers=[
        ("num", Pipeline(steps=[
            ("imputer", SimpleImputer()),
            # Масштаб после заполнения: иначе среднее и разброс считались бы по столбцу с пропусками.
            ("scale", StandardScaler()),
        ]), num_cols),
        ("cat", Pipeline(steps=[
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("onehot", OneHotEncoder(handle_unknown="ignore")),
        ]), ["district"]),
    ]
)
# fit запоминает средние, разброс и список районов. transform уже ничего не подбирает.
prep.fit(X_train)
X_train_ready = prep.transform(X_train)
print("Форма матрицы обучения:", X_train_ready.shape)
print("Имена столбцов:", list(prep.get_feature_names_out()))
# Первые три столбца — масштабированные площадь, год и комнаты.
print("Средние трёх чисел:", np.round(X_train_ready[:, :3].mean(axis=0), 4))
print("Разброс трёх чисел:", np.round(X_train_ready[:, :3].std(axis=0), 4))
```

**Критерий 9.2.** Форма `(8000, 8)`: три числа и пять районов. Пустой район не получил свой столбец: `most_frequent` подставил вместо него самый частый район обучения. Имена начинаются с `num__area` и заканчиваются районами `cat__district_восток` … `cat__district_юг`. Средние трёх чисел — нули, разброс — единицы. Печать может показать `-0.` вместо `0.`: это тот же ноль.

---

## 9.3. Регрессия: прямая и лес

Регрессия предсказывает число. Здесь это цена. `LinearRegression` ищет одну прямую: цена как сумма «площадь × вес + год × вес + комнаты × вес + вес района». Лес из занятия 6.0 режет таблицу на прямоугольники и в каждом называет свою среднюю. На этих квартирах цена как раз собрана суммой площади, года, комнат и надбавки района, поэтому прямая здесь уместна.

`score` у регрессии — R². Рядом всё равно печатают MAE: её уже умеют читать по блоку 7, и она в тех же тысячах рублей.

**Ячейка:**

```python
# Тот же prep, что в 9.2. Линейной модели нужен масштаб, лесу из второй модели — нет.
linear = Pipeline(steps=[
    ("preprocessor", prep),
    ("model", LinearRegression()),
])
linear.fit(X_train, y_train)
pred_linear = linear.predict(X_valid)
mae_linear = mean_absolute_error(y_valid, pred_linear)
# score вызывает predict сам и сравнивает с y_valid. Для регрессии это R², не MAE.
print(f"MAE прямой: {mae_linear:.2f}")
print(f"R² прямой: {linear.score(X_valid, y_valid):.4f}")

forest_prep = ColumnTransformer(
    transformers=[
        ("num", SimpleImputer(strategy="constant"), num_cols),
        ("cat", Pipeline(steps=[
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("onehot", OneHotEncoder(handle_unknown="ignore")),
        ]), ["district"]),
    ]
)
forest = Pipeline(steps=[
    ("preprocessor", forest_prep),
    ("model", RandomForestRegressor(n_estimators=30, random_state=0)),
])
forest.fit(X_train, y_train)
mae_forest = mean_absolute_error(y_valid, forest.predict(X_valid))
print(f"MAE леса: {mae_forest:.2f}")
```

**Критерий 9.3.** MAE прямой — **114.19**. R² — **0.9945**: прямая повторяет устройство цены в этом файле. MAE леса — **129.81**, та же, что у конвейера в блоке 7. На этих квартирах прямая точнее леса. Это не общий закон. Если бы цена зависела от площади «ступеньками», лес обогнал бы прямую. Вывод занятия записывают по этим двум числам, а не по привычке «лес всегда лучше».

---

## 9.4. Классификация: одобрят ли карту

Классификация предсказывает метку, а не число. В файле заявок метка `card`: карту выдали или нет. `LogisticRegression` выдаёт вероятность метки «да» и порогом 0.5 превращает её в `True` или `False`.

Столбцы `expenditure`, `share`, `active` и `majorcards` не берут. На странице про утечку они поднимали точность леса к 0.98, потому что описывают уже выданную карту. Здесь остаются `reports`, `age`, `income`, `owner`, `selfemp`, `dependents`, `months`.

Точность — доля верных меток. Она одна на обе ошибки: и «отказали по ошибке», и «одобрили по ошибке». Матрица ошибок их разделяет. Строка — что было на самом деле, столбец — что сказала модель. Порядок меток у sklearn: сначала `False`, потом `True`.

**Ячейка:**

```python
cards = pd.read_csv(
    "module-7-0/data/AER_credit_card_data.csv",
    true_values=["yes"],
    false_values=["no"],
)
safe_cols = ["reports", "age", "income", "owner", "selfemp", "dependents", "months"]
X_cards = cards[safe_cols]
y_cards = cards.card
X_card_train, X_card_valid, y_card_train, y_card_valid = train_test_split(
    X_cards, y_cards, test_size=0.25, random_state=0
)

# Масштаб нужен: возраст измеряется десятками, доход — единицами «доход / 10 000».
logit = Pipeline(steps=[
    ("scale", StandardScaler()),
    ("model", LogisticRegression(max_iter=500, random_state=0)),
])
logit.fit(X_card_train, y_card_train)
pred_card = logit.predict(X_card_valid)
print(f"Точность на проверке: {accuracy_score(y_card_valid, pred_card):.6f}")
print(confusion_matrix(y_card_valid, pred_card))

card_scores = cross_val_score(logit, X_cards, y_cards, cv=5, scoring="accuracy")
print("Точность по складкам:", [f"{float(s):.4f}" for s in card_scores])
print(f"Средняя точность: {float(card_scores.mean()):.6f}")
```

**Критерий 9.4.** Точность на проверке — **0.854545**. Матрица:

|  | Модель сказала «нет» | Модель сказала «да» |
|--|----------------------|---------------------|
| На самом деле нет | 23 | 44 |
| На самом деле да | 4 | 259 |

Ошибок «одобрили отказ» 44, ошибок «отказали одобренной заявке» только 4. Модель щедра на «да». Пять складок: **0.8447, 0.8561, 0.8598, 0.8447, 0.8327**, среднее **0.847601**. Это рядом с лесом без утечки из блока 7 (около 0.83) и далеко от 0.98 модели, которая видела расходы по карте.

---

## 9.5. Кластеризация: группы без цены

Кластеризация не предсказывает столбец. Ей не передают `y`. `KMeans` раскладывает строки на группы так, чтобы квартиры внутри группы были ближе друг к другу, чем к чужим. Близость считают по масштабированным площади, году и комнатам. Район и цену в `fit` не кладут: район — текст, цена — то, чем группу потом проверяют.

Число групп задают заранее. Здесь четыре: этого хватает, чтобы разделить «маленькая / большая» и «старше / новее». После `fit_predict` цену только усредняют внутри группы. Если средние цен разъехались, группы совпали с устройством цены, хотя модель цену не видела.

**Ячейка:**

```python
cluster_prep = Pipeline(steps=[
    ("imputer", SimpleImputer()),
    ("scale", StandardScaler()),
])
# fit_transform на всех 10000: отдельной проверки у кластеров нет, цену не угадывают.
Z = cluster_prep.fit_transform(flats[num_cols])
# n_init=10 — десять разных стартов. KMeans зависит от начальных центров, берут удачный.
groups = KMeans(n_clusters=4, n_init=10, random_state=0)
flats = flats.copy()
flats["cluster"] = groups.fit_predict(Z)
print(flats.groupby("cluster").size())
print(flats.groupby("cluster")[["area", "year", "price"]].mean().round(2))
```

**Критерий 9.5.** Четыре группы. Номера групп задаёт алгоритм, сверяют не номер, а размер и средние:

| Группа по смыслу | Строк | Средняя площадь | Средний год | Средняя цена |
|------------------|-------|-----------------|-------------|--------------|
| Меньше и новее | 2285 | 51.9 | 2008.9 | 5158.19 |
| Меньше и старше | 2175 | 48.3 | 1977.9 | 4465.02 |
| Больше и новее | 2977 | 93.9 | 2007.4 | 8576.77 |
| Больше и старше | 2563 | 90.4 | 1976.0 | 7952.12 |

Большая квартира в таблице дороже маленькой, новая при той же площади дороже старой. Кластеры это повторили, не видя `price`.

---

## 9.6. Самопроверка

1. У `SimpleImputer` есть `transform` и нет `predict`.
2. Матрица после препроцессинга имеет форму `(8000, 8)`, три первых столбца со средним 0 и разбросом 1.
3. MAE прямой 114.19, R² 0.9945, MAE леса 129.81.
4. Точность логистической регрессии на проверке 0.854545, в матрице 23, 44, 4, 259.
5. Средняя точность пяти складок 0.847601.
6. Четыре кластера размеров 2285, 2175, 2977, 2563. Самая дорогая группа — большие квартиры около 2007 года, средняя цена 8576.77.

| Симптом | Что проверить |
|---------|----------------|
| `predict` вызвался у `SimpleImputer` | Цену выдаёт модель в конце `Pipeline`, не преобразователь |
| Средние после масштаба далеко от нуля | `StandardScaler` стоит после `SimpleImputer` и `fit` вызван на обучении |
| MAE прямой близка к 1798 | В `Pipeline` не попал `prep` с районом, осталась одна площадь |
| Точность классификации около 0.98 | В `safe_cols` попали `expenditure` или `share` |
| Кластеры почти одной цены | В `KMeans` передали `price` или забыли `StandardScaler` |
| `FileNotFoundError` | Пути `module-7-0/data/flats_gaps.csv` и `module-7-0/data/AER_credit_card_data.csv` от корня курса |

После занятия слушатель различает подготовку таблицы и ответ модели, масштабирует числа перед прямой и перед кластерами, сравнивает регрессоры по MAE, классификатор читает по матрице ошибок и не кладёт цену в кластеризацию, которой потом эту цену проверяет.
