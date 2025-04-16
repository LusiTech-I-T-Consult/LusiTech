from django.shortcuts import render, redirect
from .forms import WaitlistForm
from django.contrib import messages
# Create your views here.
def index(request):
    return render(request, 'index.html')

def landing_page(request):
    form = WaitlistForm()
    return render(request, 'index.html', {'form': form})

def join_waitlist(request):
    if request.method == 'POST':
        form = WaitlistForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'Thank you for joining the waitlist!')
            return redirect('index')  # or your landing page name
    else:
        form = WaitlistForm()
    return render(request, 'index.html', {'form': form})
