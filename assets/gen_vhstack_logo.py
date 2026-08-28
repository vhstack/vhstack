import os
import numpy as np
from scipy.spatial import Delaunay
rng = np.random.default_rng(7)

N = 240
S = 512; C = S/2; R = 200
# Fibonacci sphere + jitter
i = np.arange(N) + 0.5
phi = np.arccos(1 - 2*i/N)
theta = np.pi*(1+5**0.5)*i
pts = np.stack([np.cos(theta)*np.sin(phi), np.sin(theta)*np.sin(phi), np.cos(phi)], 1)
pts += rng.normal(0, 0.06, pts.shape); pts /= np.linalg.norm(pts, axis=1)[:, None]
# rotate a bit
a = np.radians(20); Rx = np.array([[1,0,0],[0,np.cos(a),-np.sin(a)],[0,np.sin(a),np.cos(a)]])
pts = pts @ Rx.T

light = np.array([-0.5, -0.6, 0.65]); light /= np.linalg.norm(light)

def proj(p): return C + p[:,0]*R, C + p[:,1]*R

def layer(mask, front):
    P = pts[mask]; x, y = proj(P)
    tri = Delaunay(np.c_[x, y]).simplices
    out = []
    for t in tri:
        v = P[t]; n = v.mean(0); n /= np.linalg.norm(n)
        if not front: n = -n
        lam = max(0, n @ light)
        depth = (v[:,2].mean()+1)/2
        # base facet color: dark navy → teal with light
        base = np.array([8, 30, 42]) + lam*np.array([20, 70, 80])
        if front and rng.random() < 0.10:  # bright panel
            base = np.array([60, 190, 215]) * (0.6+0.4*lam)
        col = "#%02x%02x%02x" % tuple(np.clip(base, 0, 255).astype(int))
        op = (0.9 if front else 0.25*depth+0.05)
        pxy = " ".join(f"{x[k]:.1f},{y[k]:.1f}" for k in t)
        out.append((pxy, col, op))
    return out, x, y, P

back, bx, by, BP = layer(pts[:,2] < 0.15, False)
front, fx, fy, FP = layer(pts[:,2] > -0.05, True)

svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 {S} {S}">',
'''<defs>
  <radialGradient id="body" cx="40%" cy="35%" r="70%">
    <stop offset="0" stop-color="#0f3a4c"/><stop offset="0.7" stop-color="#061620"/><stop offset="1" stop-color="#02080d"/>
  </radialGradient>
  <radialGradient id="rim" cx="50%" cy="50%" r="50%">
    <stop offset="0.86" stop-color="#3fd6ee" stop-opacity="0"/><stop offset="0.97" stop-color="#3fd6ee" stop-opacity="0.35"/><stop offset="1" stop-color="#7fe8ff" stop-opacity="0.9"/>
  </radialGradient>
  <radialGradient id="halo" cx="50%" cy="50%" r="50%">
    <stop offset="0.80" stop-color="#2fc4e0" stop-opacity="0.35"/><stop offset="1" stop-color="#2fc4e0" stop-opacity="0"/>
  </radialGradient>
  <filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="1.6"/></filter>
  <filter id="shadow" x="-30%" y="-30%" width="160%" height="160%">
    <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#000" flood-opacity="0.30"/></filter>
  <clipPath id="clip"><circle cx="256" cy="256" r="200"/></clipPath>
</defs>''',
f'<circle cx="{C}" cy="{C}" r="{R+14}" fill="url(#halo)"/>',
f'<g filter="url(#shadow)"><circle cx="{C}" cy="{C}" r="{R}" fill="url(#body)"/></g>',
'<g clip-path="url(#clip)">']
# back wireframe
svg.append('<g stroke="#2fc4e0" stroke-width="0.5" fill="none">')
for pxy, col, op in back: svg.append(f'<polygon points="{pxy}" stroke-opacity="{op:.2f}"/>')
svg.append('</g>')
# front facets
svg.append('<g stroke="#3fd6ee" stroke-width="0.9" stroke-linejoin="round">')
for pxy, col, op in front: svg.append(f'<polygon points="{pxy}" fill="{col}" fill-opacity="{op}" stroke-opacity="0.85"/>')
svg.append('</g>')
# nodes with glow
svg.append('<g fill="#9ff3ff" filter="url(#glow)">')
for k in range(len(FP)):
    d = (FP[k,2]+1)/2; svg.append(f'<circle cx="{fx[k]:.1f}" cy="{fy[k]:.1f}" r="{1.6+1.6*d:.1f}" fill-opacity="{0.5+0.5*d:.2f}"/>')
svg.append('</g><g fill="#ffffff">')
for k in range(len(FP)):
    if FP[k,2] > 0.2: svg.append(f'<circle cx="{fx[k]:.1f}" cy="{fy[k]:.1f}" r="0.9"/>')
svg.append('</g></g>')
svg.append(f'<circle cx="{C}" cy="{C}" r="{R}" fill="url(#rim)"/>')
svg.append('</svg>')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'vhstack.svg')
open(OUT, 'w').write("\n".join(svg))
print("written", len("\n".join(svg))//1024, "KB")
