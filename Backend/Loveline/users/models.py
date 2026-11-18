from unicodedata import name
from django.db import models
from django.contrib.auth.models import AbstractUser 



class CustomUser(AbstractUser):
    birth_day = models.DateField(blank=False, null=False)
    gender = models.CharField(blank=False, null=False)
    profile_picture = models.ImageField(upload_to='profile_pics/', blank=True, null=True)
    filiere = models.ForeignKey(Filiere, on_delete=models.SET_NULL, null = False, blank= False, related_name='utilisateurs')
    


    def __str__(self):
        return f"{self.username}"



class Filiere(models.Model):
    name = models.CharField(blank=False, null=False)

    def __str__(self):
        return f"{self.name}"
