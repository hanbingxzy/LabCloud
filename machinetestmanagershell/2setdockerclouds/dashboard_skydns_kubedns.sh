# !bin/bash

function connect(){
  #connect internet
  curl "http://202.193.80.124/" -H "Pragma: no-cache" -H "Origin: http://202.193.80.124" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: zh-CN,zh;q=0.8" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: http://202.193.80.124/" -H "Connection: keep-alive" --data "DDDDD=g102016452&upass=03141b2b5032ba8c682103364b93ce2a123456781&R1=0&R2=1&para=00&0MKKey=123456" --compressed | grep "Please don't forget to log out after you have finished."
}
function disconnect(){
  #disconnect internet
  curl "http://202.193.80.124/F.htm" -H "Accept-Encoding: gzip, deflate, sdch" -H "Accept-Language: zh-CN,zh;q=0.8" -H "Upgrade-Insecure-Requests: 1" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Referer: http://202.193.80.124/" -H "Connection: keep-alive" --compressed >/dev/null 2>&1
}

#function dashboard_skydns_kubedns(){
   #initK8S
#}
# initK8S===dashboard_skydns_kubedns

registryHostname=
apiserver_host=
kube_master_url=

#注意：这里的IP地址（172.16.2.14）和主机名（docker1）更换为自己的IP与主机名  还要主要image的镜像地址值
function initK8S(){
  #dashboard
  cat > kubernetes-dashboard.yaml << EOF
# Configuration to deploy release version of the Dashboard UI.  
#  
# Example usage: kubectl create -f <this_file>  
  
kind: Deployment  
apiVersion: extensions/v1beta1  
metadata:  
  labels:  
    app: kubernetes-dashboard  
    version: v1.1.0  
  name: kubernetes-dashboard  
  namespace: kube-system
spec:  
  replicas: 1  
  selector:  
    matchLabels:  
      app: kubernetes-dashboard  
  template:  
    metadata:  
      labels:  
        app: kubernetes-dashboard  
    spec:  
      containers:  
      - name: kubernetes-dashboard  
        image: $registryHostname:5000/kubernetes-dashboard-amd64  
        imagePullPolicy: Always  
        ports:  
        - containerPort: 9090  
          protocol: TCP  
        args:  
          # Uncomment the following line to manually specify Kubernetes API server Host  
          # If not specified, Dashboard will attempt to auto discover the API server and connect  
          # to it. Uncomment only if the default does not work.  
          - --apiserver-host=http://$apiserver_host:8080
        livenessProbe:  
          httpGet:  
            path: /  
            port: 9090  
          initialDelaySeconds: 30  
          timeoutSeconds: 30  
---  
kind: Service  
apiVersion: v1  
metadata:  
  labels:  
    app: kubernetes-dashboard  
  name: kubernetes-dashboard  
  namespace: kube-system  
spec:  
  type: NodePort  
  ports:  
  - port: 80  
    targetPort: 9090  
  selector:  
    app: kubernetes-dashboard
EOF
  kubectl delete -f kubernetes-dashboard.yaml
  kubectl create -f kubernetes-dashboard.yaml
  kubectl get pods --all-namespaces
  kubectl describe pods/`kubectl get pods --all-namespaces | tail -n 1 | awk '{print $2}'` --namespace="kube-system"
  kubectl logs `kubectl get pods --all-namespaces | tail -n 1 | awk '{print $2}'` --namespace="kube-system"
  kubectl describe service/kubernetes-dashboard --namespace="kube-system"

  kubectl describe pods/`kubectl get pods --all-namespaces | grep 'kube-dns-v9' | tail -n 1 | awk '{print $2}'` --namespace="kube-system"
  kubectl logs `kubectl get pods --all-namespaces | grep 'kube-dns-v9' | tail -n 1 | awk '{print $2}'` --namespace="kube-system"
  
cat > skydns-rc.yaml << EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: kube-dns-v9
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    version: v9
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 1
  selector:
    k8s-app: kube-dns
    version: v9
  template:
    metadata:
      labels:
        k8s-app: kube-dns
        version: v9
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
      - name: etcd
        image: etcd
        resources:
          limits:
            cpu: 100m
            memory: 50Mi
        command:
        - /usr/local/bin/etcd
        - -data-dir
        - /var/etcd/data
        - -listen-client-urls
        - http://127.0.0.1:2379,http://127.0.0.1:4001
        - -advertise-client-urls
        - http://127.0.0.1:2379,http://127.0.0.1:4001
        - -initial-cluster-token
        - skydns-etcd
        volumeMounts:
        - name: etcd-storage
          mountPath: /var/etcd/data
      - name: kube2sky
        image: kube2sky
        resources:
          limits:
            cpu: 100m
            memory: 50Mi
        args:
        - -domain=cluster.local
        - -kube_master_url=http://$kube_master_url:8080
      - name: skydns
        image: skydns
        resources:
          limits:
            cpu: 100m
            memory: 50Mi
        args:
        - -machines=http://localhost:4001
        - -addr=0.0.0.0:53
        - -domain=cluster.local
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
      volumes:
      - name: etcd-storage
        emptyDir: {}
EOF
  cat > skydns-svc.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "KubeDNS"
spec:
  selector:
    k8s-app: kube-dns
  clusterIP: 10.254.0.3
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
EOF

  cat > kube-dns_14.yaml << EOF
apiVersion: v1
kind: ReplicationController
metadata:
  name: kube-dns-v20
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    version: v20
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 1
  selector:
    k8s-app: kube-dns
    version: v20
  template:
    metadata:
      labels:
        k8s-app: kube-dns
        version: v20
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
        scheduler.alpha.kubernetes.io/tolerations: '[{"key":"CriticalAddonsOnly", "operator":"Exists"}]'
    spec:
      containers:
      - name: kubedns
        image: kubedns-amd64
        imagePullPolicy: IfNotPresent
        resources:
          # TODO: Set memory limits when we've profiled the container for large
          # clusters, then set request = limit to keep this container in
          # guaranteed class. Currently, this container falls into the
          # "burstable" category so the kubelet doesn't backoff from restarting it.
          limits:
            memory: 170Mi
          requests:
            cpu: 100m
            memory: 70Mi
        livenessProbe:
          httpGet:
            path: /healthz-kubedns
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /readiness
            port: 8081
            scheme: HTTP
          # we poll on pod startup for the Kubernetes master service and
          # only setup the /readiness HTTP server once that's available.
          initialDelaySeconds: 3
          timeoutSeconds: 5
        args:
        # command = "/kube-dns"
        - --domain=hi
        - --dns-port=10053
        - --kube-master-url=http://$kube_master_url:8080
        ports:
        - containerPort: 10053
          name: dns-local
          protocol: UDP
        - containerPort: 10053
          name: dns-tcp-local
          protocol: TCP
      - name: dnsmasq
        image: kube-dnsmasq-amd64
        imagePullPolicy: IfNotPresent
        livenessProbe:
          httpGet:
            path: /healthz-dnsmasq
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        args:
        - --cache-size=1000
        - --no-resolv
        - --server=127.0.0.1#10053
        - --log-facility=-
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
      - name: healthz
        image: exechealthz-amd64
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: 50Mi
          requests:
            cpu: 10m
            # Note that this container shouldn't really need 50Mi of memory. The
            # limits are set higher than expected pending investigation on #29688.
            # The extra memory was stolen from the kubedns container to keep the
            # net memory requested by the pod constant.
            memory: 50Mi
        args:
        - --cmd=nslookup kubernetes.default.svc.hi 127.0.0.1 >/dev/null
        - --url=/healthz-dnsmasq
        - --cmd=nslookup kubernetes.default.svc.hi 127.0.0.1:10053 >/dev/null
        - --url=/healthz-kubedns
        - --port=8080
        - --quiet
        ports:
        - containerPort: 8080
          protocol: TCP
      dnsPolicy: Default  # Don't use cluster DNS.
---
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "KubeDNS"
spec:
  type: NodePort  
  selector:
    k8s-app: kube-dns
  clusterIP: 10.254.10.2
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
EOF

  #skydns-rc skydns-svc
  for SERVICES in kube-dns_14; do
    kubectl delete -f $SERVICES.yaml
    kubectl create -f $SERVICES.yaml  
    #kubectl apply -f nginx.yaml
    #kubectl describe pods/nginx
  done


}

initK8S
