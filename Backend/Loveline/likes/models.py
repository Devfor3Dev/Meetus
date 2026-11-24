
from django.conf import settings
from django.db import models


class Like(models.Model):
    
    class Action(models.TextChoices):
        LIKE = "like", "Like"
        DISLIKE = "dislike", "Dislike"

    liker = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="likes_given"
    )
    liked = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="likes_received"
    )
    action = models.CharField(
        max_length=10, choices=Action.choices, default=Action.LIKE
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            
            models.UniqueConstraint(fields=["liker", "liked"], name="unique_like"),
            models.CheckConstraint(
                condition=~models.Q(liker=models.F("liked")), name="no_self_like"
            ),
        ]
        indexes = [
            models.Index(fields=["liked", "action"], name="like_liked_action_idx"),
        ]

    # Méthode pour vérifier si deux utilisateurs se sont mutuellement likés
    @classmethod
    def is_mutual(cls, user_a, user_b):
        return (
            cls.objects.filter(liker=user_a, liked=user_b, action=cls.Action.LIKE).exists()
            and cls.objects.filter(liker=user_b, liked=user_a, action=cls.Action.LIKE).exists()
        )

    def __str__(self):
        return f"{self.liker} {self.action} {self.liked}"