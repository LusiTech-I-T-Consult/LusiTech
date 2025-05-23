from django.db import models

class Waitlist(models.Model):
    email = models.EmailField(unique=True)

    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.email
