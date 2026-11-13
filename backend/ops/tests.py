from django.test import TestCase
from .models import WorkItem
class OpsApiTests(TestCase):
    def test_health(self):
        self.assertEqual(self.client.get("/api/health/").status_code,200)
    def test_create_and_list_item(self):
        r=self.client.post("/api/items/create/",data='{"title":"Deploy API"}',content_type="application/json")
        self.assertEqual(r.status_code,201)
        self.assertEqual(self.client.get("/api/items/").json()["total"],1)
    def test_metrics(self):
        WorkItem.objects.create(title="Build pipeline",status="Done")
        self.assertEqual(self.client.get("/api/metrics/").json()["done"],1)
