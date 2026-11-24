import uuid

from django.contrib.auth.models import AbstractUser
from django.core.exceptions import ValidationError
from django.db import models

MAX_SIZE = 5 * 1024 * 1024  # 5 Mo


def validate_image(file):
    # 1. taille maximale
    if file.size > MAX_SIZE:
        raise ValidationError("Image trop lourde (5 Mo maximum).")
    # 2. on lit les premiers octets : le vrai type, pas le nom
    header = file.read(12)
    file.seek(0)
    is_png = header.startswith(b"\x89PNG")
    is_jpg = header.startswith(b"\xff\xd8")
    is_webp = header[:4] == b"RIFF" and header[8:12] == b"WEBP"
    if not (is_png or is_jpg or is_webp):
        raise ValidationError("Le fichier n'est pas une vraie image (PNG, JPG ou WEBP).")


def profile_upload_path(instance, filename):
    # nom aléatoire : on ne garde jamais le nom envoyé par l'utilisateur
    ext = filename.rsplit(".", 1)[-1].lower()
    return f"profile_pics/{uuid.uuid4().hex}.{ext}"


# Liste des filières (choix fermé, remplie dans l'admin)
class Filiere(models.Model):
    name = models.CharField(max_length=150, unique=True)

    def __str__(self):
        return self.name


# Liste des centres d'intérêt (choix fermé, remplie dans l'admin ou par fixture)
class Interest(models.Model):
    name = models.CharField(max_length=100, unique=True)

    def __str__(self):
        return self.name


class CustomUser(AbstractUser):
    class Gender(models.TextChoices):
        MALE = "M", "Garçon"
        FEMALE = "F", "Fille"

    # À ADAPTER : garde les valeurs exactes de ton ami si elles diffèrent
    class Status(models.TextChoices):
        MEDIUM = "medium", "Medium"
        PREMIUM = "premium", "Premium"
        GOLD = "gold", "Gold"

    email = models.EmailField(unique=True)
    birth_day = models.DateField(blank=True, null=True)
    gender = models.CharField(max_length=1, choices=Gender.choices, blank=True)
    bio = models.TextField(max_length=500, blank=True)
    profile_picture = models.ImageField(
        upload_to=profile_upload_path,
        validators=[validate_image],
        blank=True,
        null=True,
    )
    filiere = models.ForeignKey(
        Filiere,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="utilisateurs",
    )
    interests = models.ManyToManyField(Interest, blank=True, related_name="users")
    status = models.CharField(
        max_length=10, choices=Status.choices, default=Status.MEDIUM
    )

    USERNAME_FIELD = "email"        # on se connecte avec l'email
    REQUIRED_FIELDS = ["username"]  # createsuperuser demande aussi un username

    def __str__(self):
        return self.email