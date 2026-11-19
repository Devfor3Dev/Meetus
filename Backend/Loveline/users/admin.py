
from django.contrib import admin

# Register your models here.

from .models import CustomUser
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

# Register your models here.
@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    model = CustomUser
    list_display = ('username', 'email', 'filiere', 'gender', 'is_staff')
    list_filter = ('filiere', 'gender', 'is_active')
    search_fields = ('username', 'email', 'filiere__name')
    
    fieldsets = UserAdmin.fieldsets + (
        ('Profil', {'fields': ('birth_day', 'gender', 'filiere', 'profile_picture')}),
)
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Profil', {'fields': ('email', 'birth_day', 'gender', 'filiere', 'profile_picture')}),
    )
