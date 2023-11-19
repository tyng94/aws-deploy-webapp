from django.shortcuts import render

# Create your views here.
from django.http import HttpResponse
from .models import Question

def index(request):
    num = Question.objects.all().count()
    return HttpResponse(f"Hello, world. You're at the polls index. There are {num} questions.")