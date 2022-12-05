from django import forms
from django.core.validators import MinValueValidator, MaxValueValidator


class TSPForm(forms.Form):

    weightChoice = (
        (0, "00"),
        (1, "01"),
        (2, "02"),
        (3, "03"),
        (4, "04"),
        (5, "05"),
        (6, "06"),
        (7, "07"),
        (8, "08"),
        (9, "09"),

    )
    
    weightType = forms.ChoiceField(
        initial=0, choices=weightChoice, label='Weight Type')
    randomSeed = forms.IntegerField(
        initial=1, min_value=0, max_value=32000, label='Random Seed')
    numOfTrys = forms.IntegerField(
        initial=1000000, min_value=1, label='Number of Trys')
    numOfBatch = forms.IntegerField(
        initial=1, min_value=1, label=' Number of Batches')
