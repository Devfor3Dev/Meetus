from .models import CustomUser
from django.contrib import admin

# Register your models here.
@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    model = CustomUser
    fieldsets = UserAdmin.fieldsets + (
        ('Profil', {'fields' : ('birth_day', 'gender', 'filiere', 'profile_picture')})
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Profil', {'fields' : ('birth_day', 'gender', 'filiere', 'profile_picture')})
    )

    
