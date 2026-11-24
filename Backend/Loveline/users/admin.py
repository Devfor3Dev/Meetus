from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, Filiere, Interest


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    model = CustomUser

    list_display = ("username", "email", "gender", "filiere", "status", "is_staff")

    list_filter = ("gender", "filiere", "status", "is_active")
    search_fields = ("username", "email", "filiere__name")

    fieldsets = UserAdmin.fieldsets + (
        ("Profil", {"fields": (
            "birth_day", "gender", "filiere", "interests",
            "bio", "status", "profile_picture",
        )}),
    )

    add_fieldsets = UserAdmin.add_fieldsets + (
        ("Profil", {"fields": (
            "email", "birth_day", "gender", "filiere", "interests",
            "bio", "status", "profile_picture",
        )}),
    )

    # Double liste pour choisir plusieurs intérêts
    filter_horizontal = ("interests",)


@admin.register(Filiere)
class FiliereAdmin(admin.ModelAdmin):
    search_fields = ("name",)


@admin.register(Interest)
class InterestAdmin(admin.ModelAdmin):
    search_fields = ("name",)