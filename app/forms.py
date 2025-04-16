from django import forms
from .models import Waitlist

class WaitlistForm(forms.ModelForm):
    class Meta:
        model = Waitlist
        fields = ['email']
        widgets = {
            'email': forms.EmailInput(attrs={
                'class': 'form-control',
                'placeholder': 'Enter your email address',
                'required': True
            })
        }
