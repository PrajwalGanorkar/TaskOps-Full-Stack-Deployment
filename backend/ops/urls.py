from django.urls import path
from . import views
urlpatterns = [
 path("health/",views.health),
 path("items/",views.items),
 path("items/create/",views.create_item),
 path("items/<int:item_id>/",views.update_item),
 path("metrics/",views.metrics),
]
