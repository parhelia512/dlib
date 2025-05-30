/*
Copyright (c) 2011-2025 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

/**
 * Copyright: Timur Gafarov 2011-2025.
 * License: $(LINK2 boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Timur Gafarov
 */
module dlib.geometry.intersection;

import std.math;
import dlib.math.vector;
import dlib.math.utils;
import dlib.math.transformation;
import dlib.geometry.aabb;
import dlib.geometry.obb;
import dlib.geometry.plane;
import dlib.geometry.sphere;
import dlib.geometry.triangle;

/// Stores intersection data
struct Intersection
{
    bool fact = false;
    Vector3f point;
    Vector3f normal;
    float penetrationDepth;
}

/// Checks two spheres for intersection
Intersection intrSphereVsSphere(ref Sphere sphere1, ref Sphere sphere2)
{
    Intersection res;
    res.fact = false;

    float d = distance(sphere1.center, sphere2.center);
    float sumradius = sphere1.radius + sphere2.radius;

    if (d < sumradius)
    {
        res.penetrationDepth = sumradius - d;
        res.normal = (sphere1.center - sphere2.center).normalized;
        res.point = sphere2.center + res.normal * sphere2.radius;
        res.fact = true;
    }

    return res;
}

///
unittest
{
    Sphere sphere1 = Sphere(Vector3f(0, 0, 0), 1.0f);
    Sphere sphere2 = Sphere(Vector3f(1.9f, 0, 0), 1.0f);
    Intersection isec = intrSphereVsSphere(sphere1, sphere2);
    assert(isec.fact);
    assert(isConsiderZero(isec.penetrationDepth - 0.1f));
    assert(isAlmostZero(isec.point - Vector3f(0.9f, 0.0f, 0.0f)));
    assert(isAlmostZero(isec.normal - Vector3f(-1.0f, 0.0f, 0.0f)));
}

/// Checks sphere and plane for intersection
Intersection intrSphereVsPlane(ref Sphere sphere, ref Plane plane)
{
    Intersection res;
    res.fact = false;

    float q = plane.normal.dot(sphere.center - plane.d).abs;

    if (q <= sphere.radius)
    {
        res.penetrationDepth = sphere.radius - q;
        res.normal = plane.normal;
        res.point = sphere.center - res.normal * sphere.radius;
        res.fact = true;
    }

    return res;
}

///
unittest
{
    Sphere sphere = Sphere(Vector3f(0, 0.9f, 0), 1.0f);
    Plane plane = Plane(Vector3f(0, 1, 0), 0.0f);
    Intersection isec = intrSphereVsPlane(sphere, plane);
    assert(isec.fact);
    assert(isConsiderZero(isec.penetrationDepth - 0.1f));
    assert(isAlmostZero(isec.point - Vector3f(0.0f, -0.1f, 0.0f)));
    assert(isAlmostZero(isec.normal - Vector3f(0.0f, 1.0f, 0.0f)));
}

private void measureSphereAndTriVert(
        Vector3f center,
        float radius,
        ref Intersection result,
        Triangle tri,
        int whichVert)
{
    Vector3f diff = center - tri.v[whichVert];
    float len = diff.length;
    float penetrate = radius - len;
    if (penetrate > 0.0f)
    {
        result.fact = true;
        result.penetrationDepth = penetrate;
        result.normal = diff * (1.0f / len);
        result.point = center - result.normal * radius;
    }
}

void measureSphereAndTriEdge(
        Vector3f center,
        float radius,
        ref Intersection result,
        Triangle tri,
        int whichEdge)
{
    static int[] nextDim1 = [1, 2, 0];
    static int[] nextDim2 = [2, 0, 1];

    int whichVert0, whichVert1;
    whichVert0 = whichEdge;
    whichVert1 = nextDim1[whichEdge];
    float penetrate;
    Vector3f dir = tri.edges[whichEdge];
    float edgeLen = dir.length;
    if (isConsiderZero(edgeLen))
        dir = Vector3f(0.0f, 0.0f, 0.0f);
    else
        dir *= (1.0f / edgeLen);
    Vector3f vert2Point = center - tri.v[whichVert0];
    float dot = dir.dot(vert2Point);
    Vector3f project = tri.v[whichVert0] + dir * dot;
    if (dot > 0.0f && dot < edgeLen)
    {
        Vector3f diff = center - project;
        float len = diff.length;
        penetrate = radius - len;
        if (penetrate > 0.0f && penetrate < result.penetrationDepth && penetrate < radius)
        {
            result.fact = true;
            result.penetrationDepth = penetrate;
            result.normal = diff * (1.0f / len);
            result.point = center - result.normal * radius;
        }
    }
}

/// Checks sphere and triangle for intersection
Intersection intrSphereVsTriangle(ref Sphere sphere, ref Triangle tri)
{
    Intersection result;
    result.point = Vector3f(0.0f, 0.0f, 0.0f);
    result.normal = Vector3f(0.0f, 0.0f, 0.0f);
    result.penetrationDepth = 1.0e5f;
    result.fact = false;

    float distFromPlane = tri.normal.dot(sphere.center) - tri.d;

    float factor = 1.0f;

    if (distFromPlane < 0.0f)
        factor = -1.0f;

    float penetrated = sphere.radius - distFromPlane * factor;

    if (penetrated <= 0.0f)
        return result;

    Vector3f contactB = sphere.center - tri.normal * distFromPlane;

    int pointInside = tri.isPointInside(contactB);

    if (pointInside == -1) // inside the triangle
    {
        result.penetrationDepth = penetrated;
        result.point = sphere.center - tri.normal * factor * sphere.radius; //on the sphere
        result.fact = true;
        result.normal = tri.normal * factor;
        return result;
    }

    switch (pointInside)
    {
        case 0:
            measureSphereAndTriVert(sphere.center, sphere.radius, result, tri, 0);
            break;
        case 1:
            measureSphereAndTriEdge(sphere.center, sphere.radius, result, tri, 0);
            break;
        case 2:
            measureSphereAndTriVert(sphere.center, sphere.radius, result, tri, 1);
            break;
        case 3:
            measureSphereAndTriEdge(sphere.center, sphere.radius, result, tri, 1);
            break;
        case 4:
            measureSphereAndTriVert(sphere.center, sphere.radius, result, tri, 2);
            break;
        case 5:
            measureSphereAndTriEdge(sphere.center, sphere.radius, result, tri, 2);
            break;
        default:
            break;
    }

    return result;
}

///
unittest
{
    Sphere sphere = Sphere(Vector3f(0, 0.9f, 0), 1.0f);
    
    Triangle tri;
    tri.v = [
        Vector3f(0.5f, 0, -0.5f),
        Vector3f(-0.5f, 0, -0.5f),
        Vector3f(0, 0, 0.5f)
    ];
    tri.normal = Vector3f(0, 1, 0);
    tri.d = 0.0f;
    
    Intersection isec = intrSphereVsTriangle(sphere, tri);
    assert(isec.fact);
    assert(isConsiderZero(isec.penetrationDepth - 0.1f));
    assert(isAlmostZero(isec.point - Vector3f(0.0f, -0.1f, 0.0f)));
    assert(isAlmostZero(isec.normal - Vector3f(0.0f, 1.0f, 0.0f)));
}

/// Checks sphere and AABB for intersection
Intersection intrSphereVsAABB(ref Sphere sphere, ref AABB aabb)
{
    Intersection result;
    result.penetrationDepth = 0.0f;
    result.normal = Vector3f(0.0f, 0.0f, 0.0f);
    result.fact = false;

    if (aabb.containsPoint(sphere.center))
    {
        result.penetrationDepth = distance(aabb.center, sphere.center);
        result.normal = (aabb.center - sphere.center) / result.penetrationDepth;
        result.point = sphere.center + result.normal * sphere.radius;
        result.fact = true;
        return result;
    }
    else
    {
        Vector3f closest = aabb.closestPoint(sphere.center);
        Vector3f delta = closest - sphere.center;

        float distSquared = delta.lengthsqr();
        if (distSquared > sphere.radius * sphere.radius)
            return result;

        result.fact = true;
        float dist = sqrt(distSquared);
        result.penetrationDepth = sphere.radius - dist;
        result.normal = delta / dist;
        result.point = sphere.center + result.normal * sphere.radius;
        return result;
    }
}

///
unittest
{
    Sphere sphere = Sphere(Vector3f(1.5f, 0.0f, 0.0f), 1.0f);
    AABB aabb = AABB(Vector3f(0, 0, 0), Vector3f(1, 1, 1));
    Intersection intr = intrSphereVsAABB(sphere, aabb);
    assert(intr.fact);
    assert(isAlmostZero(intr.normal - Vector3f(-1.0f, 0.0f, 0.0f)));
    assert(isConsiderZero(intr.penetrationDepth - 0.5f));
}

/// Checks sphere and OBB for intersection
Intersection intrSphereVsOBB(ref Sphere s, ref OBB b)
{
    Intersection intr;
    intr.fact = false;
    intr.penetrationDepth = 0.0;
    intr.normal = Vector3f(0.0f, 0.0f, 0.0f);
    intr.point = Vector3f(0.0f, 0.0f, 0.0f);

    Vector3f relativeCenter = s.center - b.transform.translation;
    relativeCenter = b.transform.invRotate(relativeCenter);

    if (abs(relativeCenter.x) - s.radius > b.extent.x ||
        abs(relativeCenter.y) - s.radius > b.extent.y ||
        abs(relativeCenter.z) - s.radius > b.extent.z)
        return intr;

    Vector3f closestPt = Vector3f(0.0f, 0.0f, 0.0f);
    float distance;

    distance = relativeCenter.x;
    if (distance >  b.extent.x) distance =  b.extent.x;
    if (distance < -b.extent.x) distance = -b.extent.x;
    closestPt.x = distance;

    distance = relativeCenter.y;
    if (distance >  b.extent.y) distance =  b.extent.y;
    if (distance < -b.extent.y) distance = -b.extent.y;
    closestPt.y = distance;

    distance = relativeCenter.z;
    if (distance >  b.extent.z) distance =  b.extent.z;
    if (distance < -b.extent.z) distance = -b.extent.z;
    closestPt.z = distance;

    float distanceSqr = (closestPt - relativeCenter).lengthsqr;
    if (distanceSqr > s.radius * s.radius)
    return intr;

    Vector3f closestPointWorld = closestPt * b.transform;

    intr.fact = true;
    intr.normal = -(closestPointWorld - s.center).normalized;
    intr.point = closestPointWorld;
    intr.penetrationDepth = s.radius - sqrt(distanceSqr);

    return intr;
}

///
unittest
{
    Sphere sphere = Sphere(Vector3f(0, 1.9f, 0), 1.0f);
    OBB obb = OBB(Vector3f(0, 0, 0), Vector3f(1, 1, 1));
    
    Intersection isec = intrSphereVsOBB(sphere, obb);
    assert(isec.fact);
    assert(isConsiderZero(isec.penetrationDepth - 0.1f));
    assert(isAlmostZero(isec.point - Vector3f(0.0f, 1.0f, 0.0f)));
    assert(isAlmostZero(isec.normal - Vector3f(0.0f, 1.0f, 0.0f)));
}
