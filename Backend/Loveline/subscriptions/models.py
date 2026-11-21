from django.conf import settings
from django.db import models
from django.utils import timezone


class Subscription(models.Model):
    # Les 3 statuts du CDC 
    class Plan(models.TextChoices):
        MEDIUM = "medium", "Medium"
        PREMIUM = "premium", "Premium"
        GOLD = "gold", "Gold"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="subscriptions"
    )
    plan = models.CharField(max_length=10, choices=Plan.choices, default=Plan.MEDIUM)
    start_date = models.DateTimeField(default=timezone.now)
    
    end_date = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-start_date"]

    
    @property
    def is_valid(self):
        return self.end_date is None or self.end_date > timezone.now()

    def __str__(self):
        return f"{self.user} - {self.plan}"