from django.db import models

class Część_elektroniczna(models.Model):
    
    nazwa = models.CharField(max_length=30)
    opis = models.TextField()
    zdjęcie = models.ImageField(upload_to='zdjęcia')

    class Meta:
        verbose_name = "Część elektroniczna"
        verbose_name_plural = "Części elektroniczne"
