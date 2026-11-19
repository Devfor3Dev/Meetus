"""from django.contrib import admin
from .models import Like

@admin.register(Like)
class LikeAdmin(admin.ModelAdmin):
    list_display = ('liker', 'liked', 'created_at')
    list_filter('created_at')
    search_fields=(
        "liker__username",
        "liked__username",
    )
"""
