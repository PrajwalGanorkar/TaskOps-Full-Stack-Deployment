from django.db import models
class WorkItem(models.Model):
    STATUS = [("Backlog","Backlog"),("In Progress","In Progress"),("Blocked","Blocked"),("Done","Done")]
    PRIORITY = [("Low","Low"),("Medium","Medium"),("High","High"),("Critical","Critical")]
    title = models.CharField(max_length=180)
    service = models.CharField(max_length=80, default="Platform")
    description = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS, default="Backlog")
    priority = models.CharField(max_length=20, choices=PRIORITY, default="Medium")
    owner = models.CharField(max_length=80, default="Prajwal Ganorkar")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    class Meta:
        ordering = ["-updated_at"]
    def __str__(self):
        return self.title
