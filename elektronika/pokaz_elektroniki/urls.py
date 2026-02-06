from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('<int:id>/', views.strona_części_elektronicznej, name = "strona_części_elektronicznej"),
]