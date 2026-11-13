import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Count
from .models import WorkItem

def payload(request):
    try: return json.loads(request.body or b"{}")
    except (json.JSONDecodeError, UnicodeDecodeError): return None

def health(request):
    return JsonResponse({"status":"ok","service":"taskops-api","version":"1.0.0"})

def items(request):
    if request.method == "GET":
        qs = WorkItem.objects.all()
        status = request.GET.get("status")
        if status and status != "All": qs = qs.filter(status=status)
        q = request.GET.get("q")
        if q: qs = qs.filter(title__icontains=q)
        return JsonResponse({"items":[serialize(x) for x in qs], "total":qs.count()})
    return JsonResponse({"error":"Method not allowed"}, status=405)

def serialize(x):
    return {"id":x.id,"title":x.title,"service":x.service,"description":x.description,"status":x.status,"priority":x.priority,"owner":x.owner,"created_at":x.created_at.isoformat(),"updated_at":x.updated_at.isoformat()}

@csrf_exempt
def create_item(request):
    if request.method != "POST": return JsonResponse({"error":"Method not allowed"},status=405)
    data=payload(request)
    if data is None or not str(data.get("title","")).strip(): return JsonResponse({"error":"A title is required"},status=400)
    item=WorkItem.objects.create(title=str(data.get("title","")).strip(),service=data.get("service","Platform"),description=data.get("description",""),status=data.get("status","Backlog"),priority=data.get("priority","Medium"),owner=data.get("owner","Prajwal Ganorkar"))
    return JsonResponse(serialize(item),status=201)

@csrf_exempt
def update_item(request, item_id):
    if request.method == "DELETE":
        deleted,_=WorkItem.objects.filter(id=item_id).delete()
        return JsonResponse({"deleted":bool(deleted)},status=200 if deleted else 404)
    if request.method != "PATCH": return JsonResponse({"error":"Method not allowed"},status=405)
    item=WorkItem.objects.filter(id=item_id).first()
    if not item: return JsonResponse({"error":"Not found"},status=404)
    data=payload(request)
    if data is None: return JsonResponse({"error":"Invalid JSON"},status=400)
    for field in ["title","service","description","status","priority","owner"]:
        if field in data: setattr(item,field,data[field])
    item.save()
    return JsonResponse(serialize(item))

def metrics(request):
    counts={x["status"]:x["count"] for x in WorkItem.objects.values("status").annotate(count=Count("id"))}
    return JsonResponse({"total":WorkItem.objects.count(),"done":counts.get("Done",0),"in_progress":counts.get("In Progress",0),"blocked":counts.get("Blocked",0),"backlog":counts.get("Backlog",0)})
