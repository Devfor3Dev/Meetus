
from django.db import models
from django.contrib.auth.models import AbstractUser 
# Create your models here.

class User(AbstractUser):
    birth_day = models.DateField(blank=False, null=False)
    gender = models.CharField(null=False, blank = False)
    profile_picture = models.ImageField(upload_to='Images/profil_picture', blank=True, null=True)


    def __str__(self):
        return f"{self.email}"
