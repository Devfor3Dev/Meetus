from unicodedata import name
from django.db import models
from django.contrib.auth.models import AbstractUser 

"""
Ne pas oubier de changer le blank true et null true par false au niveau de birth_day, gender et filiere
"""

class Filiere(models.Model):
    name = models.CharField(blank=False, null=False)

    def __str__(self):
        return f"{self.name}"

class CustomUser(AbstractUser):
    email = models.EmailField(unique=True, blank=False, null=False)
    birth_day = models.DateField(blank=True, null=True)
    gender = models.CharField(max_length = 30, blank=True, null=True)
    profile_picture = models.ImageField(upload_to='profile_pics/', blank=True, null=True)
    filiere = models.ForeignKey(Filiere, on_delete=models.SET_NULL, null = True, blank= True, related_name='utilisateurs')
    


    def __str__(self):
        return f"{self.email}"

