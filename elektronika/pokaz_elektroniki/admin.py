from django.contrib import admin
from .models import Część_elektroniczna

class Część_elektroniczna_admin(admin.ModelAdmin):
    list_display = ('nazwa', 'opis')
    search_fields = ('nazwa',)
    fieldsets = (
        ('Informacje', {
            'fields': ('nazwa', 'opis')
        }),
        ('Zdjęcie', {
            'fields': ('zdjęcie',)
        }),
    )

admin.site.register(Część_elektroniczna, Część_elektroniczna_admin)