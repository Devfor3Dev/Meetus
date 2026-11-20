from .models import CustomUser, Filiere
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin


@admin.register(Filiere)
class FiliereAdmin(admin.ModelAdmin):
    list_display = ('id', 'name')
    search_fields = ('name',)


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    model = CustomUser
    list_display = ('username', 'email', 'filiere', 'gender', 'status', 'is_staff')
    list_filter = ('filiere', 'gender', 'status', 'is_active')
    search_fields = ('username', 'email', 'filiere__name')

    fieldsets = UserAdmin.fieldsets + (
        ('Profil', {'fields': ('birth_day', 'gender', 'bio', 'hobbies', 'status', 'filiere', 'profile_picture')}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Profil', {'fields': ('email', 'birth_day', 'gender', 'bio', 'hobbies', 'status', 'filiere', 'profile_picture')}),
    )