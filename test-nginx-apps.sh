#!/bin/bash

# Test script for nginx applications in both GKE clusters
echo "=== Testing nginx applications in GKE clusters ==="
echo

# Get cluster IPs from Terraform output
CLUSTER1_IP="34.121.230.139"
CLUSTER2_IP="34.44.230.72"

echo "Cluster 1 IP: $CLUSTER1_IP"
echo "Cluster 2 IP: $CLUSTER2_IP"
echo

# Test 1: Basic connectivity test
echo "=== Test 1: Basic Connectivity ==="
echo "Testing Cluster 1..."
curl -o /dev/null -s -w "Status: %{http_code}, Time: %{time_total}s, Size: %{size_download} bytes\n" http://$CLUSTER1_IP

echo "Testing Cluster 2..."
curl -o /dev/null -s -w "Status: %{http_code}, Time: %{time_total}s, Size: %{size_download} bytes\n" http://$CLUSTER2_IP
echo

# Test 2: Content verification
echo "=== Test 2: Content Verification ==="
echo "Cluster 1 response (first 3 lines):"
curl -s http://$CLUSTER1_IP | head -3
echo

echo "Cluster 2 response (first 3 lines):"
curl -s http://$CLUSTER2_IP | head -3
echo

# Test 3: Load testing (multiple requests)
echo "=== Test 3: Load Testing (10 requests each) ==="
echo "Testing Cluster 1 load handling..."
for i in {1..10}; do
    response_time=$(curl -o /dev/null -s -w "%{time_total}" http://$CLUSTER1_IP)
    echo "Request $i: ${response_time}s"
done
echo

echo "Testing Cluster 2 load handling..."
for i in {1..10}; do
    response_time=$(curl -o /dev/null -s -w "%{time_total}" http://$CLUSTER2_IP)
    echo "Request $i: ${response_time}s"
done
echo

# Test 4: Kubernetes-level tests
echo "=== Test 4: Kubernetes Resource Status ==="
echo "Cluster 1 pods:"
kubectl get pods -n applications --context=gke_project-2-469918_us-central1-a_app-cluster-1

echo
echo "Cluster 2 pods:"
kubectl get pods -n applications --context=gke_project-2-469918_us-central1-a_app-cluster-2

echo
echo "Cluster 1 service:"
kubectl get svc -n applications --context=gke_project-2-469918_us-central1-a_app-cluster-1

echo
echo "Cluster 2 service:"
kubectl get svc -n applications --context=gke_project-2-469918_us-central1-a_app-cluster-2

echo
echo "=== Test 5: Pod Health Check ==="
echo "Testing individual pods in Cluster 1:"
kubectl exec -n applications $(kubectl get pods -n applications --context=gke_project-2-469918_us-central1-a_app-cluster-1 -o name | head -1 | cut -d'/' -f2) --context=gke_project-2-469918_us-central1-a_app-cluster-1 -- curl -s localhost:80 | head -1

echo
echo "Testing individual pods in Cluster 2:"
kubectl exec -n applications $(kubectl get pods -n applications --context=gke_project-2-469918_us-central1-a_app-cluster-2 -o name | head -1 | cut -d'/' -f2) --context=gke_project-2-469918_us-central1-a_app-cluster-2 -- curl -s localhost:80 | head -1

echo
echo "=== All tests completed! ==="
