# Python Basis Concepten

In deze les gaan we de basis concepten van Python leren. Deze kennis is essentieel voor het schrijven van effectieve scripts en het werken met Microsoft Graph.

## Variabelen en Datatypes

### Variabelen Definiëren

```python
# Basis variabelen
naam = "Jan"
leeftijd = 30
is_actief = True
prijs = 19.99

# Type hints (optioneel)
email: str = "jan@contoso.com"
aantal: int = 42
datum: datetime = datetime.now()
```

### Datatypes

Python ondersteunt verschillende datatypes:

1. **Strings (Tekst)**
   ```python
   tekst = "Dit is een string"
   tekst2 = 'Dit is ook een string'
   multiline = """
   Dit is een
   multiline string
   """
   ```

2. **Numbers (Getallen)**
   ```python
   integer = 42
   float_num = 3.14
   complex_num = 1 + 2j
   ```

3. **Booleans (Waar/Onwaar)**
   ```python
   is_waar = True
   is_onwaar = False
   ```

4. **None (Null)**
   ```python
   leeg = None
   ```

## Lists, Dictionaries en Sets

### Lists (Arrays)

```python
# Eenvoudige list
namen = ["Jan", "Piet", "Marie"]

# List met verschillende datatypes
gemengd = ["Tekst", 42, True, datetime.now()]

# List operaties
namen.append("Sophie")  # Toevoegen
namen.remove("Piet")    # Verwijderen
namen.sort()           # Sorteren
namen.reverse()        # Omkeren

# List comprehension
getallen = [x for x in range(10)]
kwadraten = [x**2 for x in range(5)]
```

### Dictionaries (Hashtables)

```python
# Basis dictionary
config = {
    "naam": "Test App",
    "versie": "1.0",
    "actief": True
}

# Nested dictionary
complex_config = {
    "database": {
        "server": "localhost",
        "port": 1433
    },
    "api": {
        "endpoint": "https://api.example.com",
        "key": "secret123"
    }
}

# Dictionary operaties
config["nieuwe_setting"] = "waarde"  # Toevoegen
del config["versie"]                 # Verwijderen
versie = config.get("versie", "1.0") # Veilig ophalen
```

### Sets

```python
# Basis set
unieke_namen = {"Jan", "Piet", "Marie"}

# Set operaties
unieke_namen.add("Sophie")    # Toevoegen
unieke_namen.remove("Piet")   # Verwijderen
unieke_namen.discard("Jan")   # Veilig verwijderen

# Set operaties
set1 = {1, 2, 3}
set2 = {3, 4, 5}

unie = set1 | set2           # Union
intersectie = set1 & set2    # Intersection
verschil = set1 - set2       # Difference
```

## Control Flow

### If/Else Statements

```python
# Eenvoudige if/else
if leeftijd >= 18:
    print("Je bent volwassen")
else:
    print("Je bent minderjarig")

# If/elif/else
if score >= 90:
    print("Uitstekend!")
elif score >= 70:
    print("Goed")
elif score >= 50:
    print("Voldoende")
else:
    print("Onvoldoende")
```

### Loops

```python
# For loop met list
for naam in namen:
    print(f"Hallo {naam}!")

# For loop met range
for i in range(5):
    print(f"Teller: {i}")

# While loop
teller = 0
while teller < 5:
    print(f"Teller: {teller}")
    teller += 1
```

## Functions en Modules

### Functions

```python
# Eenvoudige function
def get_greeting(naam: str) -> str:
    return f"Hallo {naam}!"

# Function met parameters
def set_user_info(naam: str, leeftijd: int = 0, status: str = "Actief") -> None:
    print(f"Naam: {naam}")
    print(f"Leeftijd: {leeftijd}")
    print(f"Status: {status}")

# Function met *args en **kwargs
def print_args(*args, **kwargs):
    print("Args:", args)
    print("Kwargs:", kwargs)
```

### Modules

```python
# Module importeren
import datetime
from typing import List, Dict

# Module met alias
import json as json_module

# Specifieke items importeren
from datetime import datetime, timedelta

# Custom module maken
# user_management.py
def get_user_info(username: str) -> Dict:
    return {
        "naam": username,
        "email": f"{username}@contoso.com",
        "afdeling": "IT"
    }

# main.py
from user_management import get_user_info
```

## Error Handling

### Try/Except/Finally

```python
# Basis try/except
try:
    result = 1/0
except ZeroDivisionError:
    print("Kan niet delen door nul")

# Met finally
try:
    file = open("test.txt", "w")
    file.write("Test data")
except IOError as e:
    print(f"Fout bij bestandsoperatie: {e}")
finally:
    file.close()

# Meerdere except blocks
try:
    # Gevaarlijke code
    pass
except ValueError as e:
    print(f"Waarde fout: {e}")
except TypeError as e:
    print(f"Type fout: {e}")
except Exception as e:
    print(f"Onverwachte fout: {e}")
```

## Best Practices

1. **Code Stijl**
   - Volg PEP 8 richtlijnen
   - Gebruik beschrijvende variabele namen
   - Schrijf docstrings voor functions
   - Gebruik type hints

2. **Error Handling**
   - Gebruik specifieke except blocks
   - Log fouten adequaat
   - Cleanup in finally blocks

3. **Performance**
   - Gebruik list comprehension
   - Vermijd onnodige loops
   - Gebruik sets voor unieke items

## Volgende Stap

Nu je de basis concepten van Python kent, gaan we in de volgende les kijken naar [Python en Microsoft Graph](03_02_graph_basics.md). Daar leren we hoe we de Microsoft Graph API kunnen gebruiken in Python. 