# LAB 4: Orchestrated deployment of a decomposed application

In this lab we introduce how to orchestrate a multi-container application in
OpenShift.

[comment]: <> (#TODO)
This lab should be performed on **YOUR ASSIGNED AWS VM** as `ec2-user` unless
otherwise instructed.

Expected completion: 40-60 minutes

Let's start with a little more experimentation locally before looking to
OpenShift. I am sure you are all excited about your new blog site! And, now that
it is getting super popular with 1,000s of views per day, you are starting to
worry about uptime.

So, let's see what will happen. Launch the site:

```bash
$ sudo podman run -d -p 8080:8080 -v ~/workspace/pv/uploads:/var/www/html/wp-content/uploads:z -e DB_ENV_DBUSER=user -e DB_ENV_DBPASS=mypassword -e DB_ENV_DBNAME=mydb -e DB_HOST=0.0.0.0 -e DB_PORT=3306 --name wordpress wordpress
$ sudo podman run -d --network=container:wordpress -v ~/workspace/pv/mysql:/var/lib/mysql:z -e DBUSER=user -e DBPASS=mypassword -e DBNAME=mydb --name mariadb mariadb
```

Use `curl` again to validate that the site is working:

```bash
$ curl -L http://localhost:8080
```

As you learned before, you can confirm the port that your server is running on
by executing:

```bash
$ sudo podman ps
$ sudo podman port wordpress
8080/tcp -> 0.0.0.0:8080
```

First, let's get the container ID of the running database so that we can use it
for various experiments. Then, let's see what happens when we kick over the
database:

```bash
$ OLD_CONTAINER_ID=$(sudo podman inspect --format '{{ .ID }}' mariadb)
$ sudo podman stop mariadb
```

Take a look at the site in your web browser or using curl now. And, imagine
explosions! (*making sound effects will be much appreciated by your lab mates.*)

```bash
$ curl -L http://localhost:8080
```

While containers are typically ephemeral, because we have attached a volume from
the host into the container, the data lives across restarts and even container
deletion. This allows you to bring the database back without having lost any
data:

```bash
$ sudo podman start mariadb
```

Now, let's compare the old container id and the new one:
```bash
$ NEW_CONTAINER_ID=$(sudo podman inspect --format '{{ .ID }}' mariadb)
$ echo -e "$OLD_CONTAINER_ID\n$NEW_CONTAINER_ID"
```

The container IDs are exactly the same. This is because you simply stopped the
DB container and then restarted it. Had you completely deleted it (`podman rm`)
and recreated it, you would have gotten a new container ID. 

Overall this is similar to having had two virtual machines running a web server
and a database running, but a whole lot faster to create, stop, and restart. Let's
take a look at the site now:

```bash
$ curl -L http://localhost:8080
```

It's back!

Finally, let's kill off these containers to prepare for the next section.

```bash
$ sudo podman rm -f mariadb wordpress
```

Starting and stopping is definitely easy, and fast. However, it is still pretty
manual. What if we could automate the recovery? Or, in buzzword terms, "ensure
the service remains available"? Enter Kubernetes/OpenShift.

## Using OpenShift

Login to OpenShift & connect to your project:

```bash
$ oc login -u $OS_USER -p $OS_PASS
$ oc project $OS_USER-container-lab
```

You are now logged in to OpenShift and are using your own project. You can also
view the OpenShift web console by using the same credentials and the URL that
you were previously given for the console.

## Adjust Users

OpenShift has many built-in default security features. One of these default
security enhancements is that containers are run as randomized user IDs, and any
`USER` specified in the container's `Dockerfile` is ignored. The container is
run with the `root` group, though (GID 0).

Because of this randomization, it's a good idea to test/validate that your
container works when run as a high, unprivileged user ID (greater than 1000).
The `apache` user is `48` so we need to adjust our container a little bit and
see what happens. Although we are going to do our testing in the actual
OpenShift environment.

We are going to change the user to be `1001` and the group to be `0` (`root`)
and then give both the user and group write access on the `/run/php-fpm/`
directory.

**_NOTE_**: The `Dockerfile` referenced is the one in the `lab3` folder's
`wordpress' folder.

```bash
$ vi wordpress/Dockerfile
```

modify these two lines:

```bash
RUN chown 48:48 /run/php-fpm
RUN chmod 0755 /run/php-fpm
```

to be:

```bash
RUN chown 1001:0 /run/php-fpm
RUN chmod 0775 /run/php-fpm
```

then save and exit (`ESC :wq`). Make sure you change the directory permissions
for `php-fpm` to be `775` (which is group writeable). If you forget that, you
will get an error whe `php-fpm` tries to start.

Once the change is made, we need to rebuild the container image (remember
container images are immutable) and push it to the OpenShift Registry.

```bash
  $ sudo podman build -t wordpress wordpress/
  $ sudo podman tag localhost/wordpress $OS_REGISTRY/$OS_USER-container-lab/wordpress
  $ sudo podman login --tls-verify=false \
    -u $OS_USER \
    -p $(oc whoami -t) \
    $OS_REGISTRY
  $ sudo podman push --tls-verify=false $OS_REGISTRY/$OS_USER-container-lab/wordpress
```

You might notice that this push was a lot faster. This is because the registry
is smart and understands that the layers being pushed are identical, so it tells
Podman it can be skipped. Since we only changed a few things in the
`Dockerfile`, most of the layers are the same.

## Orphaned images

When you run the tag command above, you are telling Podman to replace the tag that you previously pointed at `localhost/wordpress`. When you don't specify the specific tag, the `build` command will automatically use `:latest`. Go ahead and look at the images:

```bash
$ sudo podman images
```

You should see an image whose repository is `<none>`. This is because
`localhost/wordpress:latest` was rebuilt and got a new image ID/SHA, and then
you updated the `$OS_REGISTRY/$OS_USER-container-lab/wordpress:latest` tag to
point at the new build of Wordpress. This effectively orphaned the old image.
When doing a lot of local container building and tagging with Podman, take care
to occasionally clean up after yourself.

We'll ignore this for now, and know that OpenShift has various cleaning routines
to take care of these things for you.
## Pod Creation

Let's get started by talking about a pod. A pod is a set of containers that
provide one "service." How do you know what to put in a particular pod? Well, a
pod's containers need to be co-located on a host and need to be spawned and
re-spawned together. So, if the containers always need to be running on the same
container host, well, then they should be a pod.

**_NOTE:_** We will be putting this file together in steps to make it easier to
explain what the different parts do. We will be identifying the part of the
file to modify by looking for an "empty element" that we inserted earlier and
then replacing that with a populated element.

Let's make a pod for mariadb. Open a file called mariadb-pod.yaml.

```bash
$ mkdir -p ~/workspace/mariadb/openshift
$ vi ~/workspace/mariadb/openshift/mariadb-pod.yaml
```

In that file, let's put in the pod identification information:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mariadb
  labels:
    name: mariadb
spec:
  containers:
```

We specified the version of the Kubernetes API, the name of this pod (aka
```name```), the ```kind``` of Kubernetes thing this is, and a ```label``` which
lets other Kubernetes things find this one.

Generally speaking, this is the content you can copy and paste between pods,
aside from the names and labels.

Now, let's add the custom information regarding this particular container. To
start, we will add the most basic information. Please replace the
```containers:``` line with:

```yaml
  containers:
  - name: mariadb
    image: image-registry.openshift-image-registry.svc:5000/openshift/mariadb
    ports:
    - containerPort: 3306
    env:
```

Here we set the `name` of the container; remember we can have more than
one in a pod. We also set the `image` to pull, in other words, the container
image that should be used and the registry to get it from.

Lastly, we need to configure the environment variables that need to be fed from
the host environment to the container. Replace `env:` with:

```yaml
    env:
      - name: MYSQL_USER
        value: user
      - name: MYSQL_PASSWORD
        value: mypassword
      - name: MYSQL_DATABASE
        value: mydb
```

OK, now we are all done, and should have a file that looks like:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mariadb
  labels:
    name: mariadb
spec:
  containers:
    - name: mariadb
      image: image-registry.openshift-image-registry.svc:5000/openshift/mariadb
      ports:
        - containerPort: 3306
      env:
        - name: MYSQL_USER
          value: user
        - name: MYSQL_PASSWORD
          value: mypassword
        - name: MYSQL_DATABASE
          value: mydb
```

**_Note:_** OpenShift provides an image for MariaDB as well as for several other
software components. These come from the (Application
Streams)[https://developers.redhat.com/blog/2018/11/15/rhel8-introducing-appstreams]
which may sound familiar to you if you have used the Software Collections
Libraries (SCL) in the past. This image has specific environment variables it is
configured to use, so this is why you are seeing different names than we used
when we built our own Maria image.

Our Wordpress container is much less complex, so let's do that pod next.

**_Note_:** **YOU WILL NEED TO CHANGE `YOUR_OS_USER` TO HAVE THE VALUE OF YOUR
OPENSHIFT USERNAME**. For example, `user1`, if that's what your user is. If you
do not correctly substitute your username, you will notice that your Wordpress
container will fail to run due to the image not being found.

```bash
$ mkdir -p ~/workspace/wordpress/openshift
$ vi ~/workspace/wordpress/openshift/wordpress-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wordpress
  labels:
    name: wordpress
spec:
  containers:
  - name: wordpress
    image: image-registry.openshift-image-registry.svc:5000/YOUR_OS_USER-container-lab/wordpress
    ports:
    - containerPort: 8080
    env:
    - name: DB_ENV_DBUSER
      value: user
    - name: DB_ENV_DBPASS
      value: mypassword
    - name: DB_ENV_DBNAME
      value: mydb
```

There are a couple of things to notice about this file. Obviously, we change all
the appropriate names to reflect "wordpress" but, largely, it is the same as the
mariadb pod file. We also use the environment variables that are specified by
the wordpress container, although they need to get the same values as the ones
in the mariadb pod.

Ok, so, let's launch our pods and make sure they come up correctly. In order to
do this, we need to introduce the `oc` command which is what drives OpenShift.
Generally, speaking, the format of `oc` commands is `oc <operation> <kind>`.
Where `<operation>` is something like `create`, `get`, `remove`, etc. and `kind`
is the `kind` from the pod files.

```bash
$ oc create -f ~/workspace/mariadb/openshift/mariadb-pod.yaml
$ oc create -f ~/workspace/wordpress/openshift/wordpress-pod.yaml
```

Now, I know i just said, `kind` is a parameter, but, as this is a create
statement, it looks in the `-f` file for the `kind`.

Ok, let's see if they came up:

```bash
$ oc get pods
```

Which should output two pods, one called `mariadb` and one called
`wordpress` . You can also check the OpenShift web console if you already
have it pulled up and verify the pods show up there as well.

If you have any issues with the pods transistioning from a "Pending" state, you
can check out the logs from the OpenShift containers in multiple ways. Here are
a couple of options:

```bash
$ oc logs mariadb
$ oc describe pod mariadb

$ oc logs wordpress
$ oc describe pod wordpress
```

Ok, now let's kill them off so we can introduce the services that will let them
more dynamically find each other.

```bash
$ oc delete pod/mariadb pod/wordpress
```

Verify they are terminating or are gone:

```bash
$ oc get pods
```

**_NOTE_:** you used the "singular" form here on the `kind`, which, for delete,
is required and requires a "name". However, you can, usually, use them
interchangeably depending on the kind of information you want.

## Service Creation

Now we want to create Kubernetes Services for our pods so that OpenShift can
introduce a layer of indirection between the pods.

Let's start with mariadb. Open up a service file:

```bash
$ vi ~/workspace/mariadb/openshift/mariadb-service.yaml
```

and insert the following content:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mariadb
  labels:
    name: mariadb
spec:
  ports:
  - port: 3306
  selector:
    name: mariadb
```

As you can probably tell, there isn't really anything new here. However, you
need to make sure the `kind` is of type `Service` and that the
`selector` matches at least one of the `labels` from the pod file. The
`selector` is how the service finds the pods that should be associated.

OK, now let's move on to the Wordpress service. Open up a new service file:

```bash
$ vi ~/workspace/wordpress/openshift/wordpress-service.yaml
```

and insert:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  labels:
    name: wordpress
spec:
  ports:
  - port: 8080
  selector:
    name: wordpress
```

Here you may notice there is no reference to the wordpress pod at all. Any pod
that provides "wordpress capabilities" can be targeted by this service. Pods can
claim to provide "wordpress capabilities" through their labels. This service is
programmed to target pods with a label of `name: wordpress`.

Another example of this might have been if we had made the mariadb-service just
a "db" service and then, the pod could be mariadb, mysql, sqlite, anything
really, that can support SQL the way wordpress expects it to. In order to do
that, we would just have to add a `label` to the `mariadb-pod.yaml`
called "db" and a `selector` in the `mariadb-service.yaml` (although, an
even better name might be `db-service.yaml`) called `db`. Feel free to
experiment with that at the end of this lab if you have time.

Now let's get things going. Start mariadb:

```bash
$ oc create -f ~/workspace/mariadb/openshift/mariadb-pod.yaml -f ~/workspace/mariadb/openshift/mariadb-service.yaml
```

Now let's start wordpress.

```bash
$ oc create -f ~/workspace/wordpress/openshift/wordpress-pod.yaml -f ~/workspace/wordpress/openshift/wordpress-service.yaml
```

OK, now let's make sure everything came up correctly:

```bash
$ oc get pods
$ oc get services
```

**_NOTE_:** these may take a while to get to a `RUNNING` state as it pulls
the image from the registry, spins up the containers, etc.

Eventually, you should see:

```bash
$ oc get pods
NAME        READY     STATUS    RESTARTS   AGE
mariadb     1/1       Running   0          45s
wordpress   1/1       Running   0          42s
```

```bash
$ oc get services
NAME        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
mariadb     ClusterIP   172.30.xx.xx    <none>        3306/TCP   1m
wordpress   ClusterIP   172.30.xx.xx    <none>        8080/TCP   1m
```

You can also see that the services have found pods by looking at the `Endpoint` lists:

```bash
$ oc get endpoints
```

Which will show something like:

```
NAME        ENDPOINTS          AGE
mariadb     10.128.2.31:3306   2m12s
wordpress   10.128.2.32:8080   115s
```

Those IPs are inside OpenShift's software-defined network and are not accessible from your lab machine.

You can make the Wordpress service available outside the cluster by using a `Route`. `Route`s are a special kind of `Ingress` resource unique to OpenShift with their own properties. You can learn more about the differences in (this article)[https://cloud.redhat.com/blog/kubernetes-ingress-vs-openshift-route]. `oc` provides a convenient way to create a `Route` from a `Service` using the `expose` subcommand:

```bash
$ oc expose svc/wordpress
```

And you should be able to see the service's accessible URL by viewing the
routes:

```bash
$ oc get routes
NAME        HOST/PORT                                                                     PATH   SERVICES    PORT   TERMINATION   WILDCARD
wordpress   wordpress-<YOUR_USER>-container-lab.<CLUSTER_DEFAULT>          wordpress   8080                 None
```

Check and make sure you can access the wordpress service through the route:

```bash
$ curl -L http://wordpress-<YOUR_USER>-container-lab.apps.<YOUR HOSTNAME>
```

OR open the URL in a browser to view the UI.

Look at that, it works!

There is no SSL termination configured for this `Route`. OpenShift provides
convenient ways to do this, but we will not cover them in this lab. 

Also, we have not attached any persistent storage to the database container, or
to Wordpress. If you were to kill or recreate these pods, all of their storage
would disappear because, just like locally with Podman, the storage is
ephemeral. OpenShift has a storage subsystem that makes it easy to attach
storage to Pods, but that will not be covered in this lab.

Similarly, there is nothing keeping track of the status of these Pods. In other
words, if one of them were to die for whatever reason, OpenShift would just let
you know that it was no longer running when you asked. Kubernetes and OpenShift
provide a way to keep pods running through the use of `Deployments`. There are
many additional topics on resiliency and scale that you may wish to explore. Now
that you are finished with this lab, perhaps browse https://learn.openshift.com
and explore additional topics!
