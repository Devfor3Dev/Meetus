from django.core.exceptions import ValidationError
from django.conf import settings
from django.db import models
import uuid
from django.db.models import F, Q

class Conversation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user1 = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,related_name="conversations_as_user1",)
    user2 = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,related_name="conversations_as_user2",)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True, db_index=True)


    class Meta:
        ordering = ["-updated_at"]
        constraints = [
            models.CheckConstraint(
                condition=~Q(user1=F("user2")),
                name="prevent_self_conversation",
            ),
            models.UniqueConstraint(
                fields=["user1", "user2"],
                name="unique_direct_conversation",
            ),
        ]
    

    def clean(self):
        if self.user1_id and self.user2_id:
            if self.user1_id == self.user2_id:
                raise ValidationError("user cant't chat with himself")
            if self.user1_id > self.user2_id:
                self.user1, self.user2 = self.user2, self.user1
            

        
    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)


    def __str__(self):
        return f"{self.user1} ↔ {self.user2}"
