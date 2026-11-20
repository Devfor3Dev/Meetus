from django.conf import settings
from django.db import models


class Notification(models.Model):
    
    class Type(models.TextChoices):
        LIKE = "like", "Like reçu"
        MESSAGE = "message", "Message reçu"
        PROMO = "promo", "Offre promotionnelle"
        UPDATE = "update", "Mise à jour de la plateforme"
        EVENT = "event", "Opportunité événementielle"

    
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications"
    )
    
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name="notifications_sent",
    )
    type = models.CharField(max_length=10, choices=Type.choices)
    message = models.CharField(max_length=255)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]  

    def __str__(self):
        return f"{self.type} -> {self.recipient}"