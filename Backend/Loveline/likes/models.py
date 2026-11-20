
from django.db import models
from django.contrib.auth import settings


# Create your models here.
class Like(models.Model):
    liker = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='likes_given')
    liked = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='likes_received')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['liker', 'liked'], name='unique_like'),
            models.CheckConstraint(condition=~models.Q(liker=models.F('liked')), name='no_self_like'),
        ]
        def __str__(self):
            return f"{self.liker} likes {self.liked}"

