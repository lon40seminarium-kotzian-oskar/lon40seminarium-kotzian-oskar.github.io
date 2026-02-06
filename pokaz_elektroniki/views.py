from django.shortcuts import render, get_object_or_404
from pokaz_elektroniki.models import Część_elektroniczna

def index(request):

    części_elektroniczne =  Część_elektroniczna.objects.all()

    return render(request, 'pokaz_elektroniki/index.html', {'części_elektroniczne': części_elektroniczne})

def strona_części_elektronicznej(request, id):

    część = get_object_or_404(Część_elektroniczna, id=id)

    return render(request, 'pokaz_elektroniki/strona_części_elektronicznej.html', {'część' : część})