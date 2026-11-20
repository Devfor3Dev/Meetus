from django.contrib import admin
from .models import Conversation


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ('id', 'user1', 'user2', 'created_at', 'updated_at')
    list_filter = ('created_at', 'updated_at')
    search_fields = (
        'user1__username',
        'user1__email',
        'user2__username',
        'user2__email',
    )
    readonly_fields = ('id', 'created_at', 'updated_at')

