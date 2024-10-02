# Optical Network Resource Allocation Model

###############################################################################
#                                 MODEL SECTION                                #
###############################################################################

# Sets
set N;                    # Set of nodes
set L within {N, N};      # Set of links (defined as node pairs)
set R;                    # Set of requests
set Types;                # Set of request types (m1, m2, m3, m4)
set Z;                    # Set of zones
set P{R};                 # Set of paths for each request
set C{R};                 # Set of possible starting slots for each request
set LinksInPath{r in R, p in P[r]} within L;  # Links in each path

# Parameters
param B >= 0, integer;    # Total number of spectrum slots per link

param slot_req{Types} >= 0, integer;     # Slots required for each type
param type{R} symbolic in Types;         # Type of each request
param zone_type{Z} symbolic in Types;    # Type of requests allowed in each zone
param zone_capacity{Z} >= 0, integer;    # Capacity of each zone

# Variables
var x{r in R, p in P[r]} binary;       # Path selection
var y{r in R, s in C[r]} binary;       # Starting slot selection
var z_alloc{r in R, s in C[r]} binary; # Slot allocation
var a{R} binary;                       # Request acceptance

# Objective: Maximize the number of accepted requests
maximize Total_Accepted: sum{r in R} a[r];

# Constraints

# 1. Path and slot assignment for accepted requests
subject to Path_Assignment {r in R}:
    sum{p in P[r]} x[r,p] = a[r];

subject to Slot_Assignment {r in R}:
    sum{s in C[r]} y[r,s] = a[r];

# 2. Spectrum contiguity and slot allocation
subject to Spectrum_Contiguity {r in R, s in C[r]}:
    z_alloc[r,s] <= y[r,s];

subject to Slot_Allocation {r in R}:
    sum{s in C[r]} z_alloc[r,s] = slot_req[type[r]] * a[r];

# 3. Path-slot consistency
subject to Path_Slot_Consistency {r in R, p in P[r], s in C[r]}:
    y[r,s] <= x[r,p];

# 4. Continuous slot assignment along path
subject to Continuous_Slot_Assignment {r in R, p in P[r], (i,j) in LinksInPath[r,p], s in C[r], z in Z: zone_type[z] = type[r]}:
    z_alloc[r,s] <= x[r,p];

# 5. Non-overlapping slots in each zone
subject to Non_Overlapping {(i,j) in L, t in 1..B, z in Z}:
    sum{r in R, p in P[r], s in C[r]: 
        (i,j) in LinksInPath[r,p] and 
        s <= t and 
        t < s + slot_req[type[r]] and 
        zone_type[z] = type[r]} z_alloc[r,s] <= 1;

# 6. Zone capacity constraints
subject to Zone_Capacity {z in Z, (i,j) in L}:
    sum{r in R, p in P[r], s in C[r]: 
        (i,j) in LinksInPath[r,p] and 
        zone_type[z] = type[r]} z_alloc[r,s] <= zone_capacity[z];

# 7. Dedicated zone allocation
subject to Dedicated_Zone_Allocation {r in R, z in Z, (i,j) in L, s in C[r]}:
    z_alloc[r,s] <= if zone_type[z] = type[r] then 1 else 0;

###############################################################################
#                                 DATA SECTION                                 #
###############################################################################

data;

# Network topology
set N := 1 2 3 4 5;
set L := (1,2) (2,1) (1,4) (4,1) (2,3) (3,2) (2,5) (5,2) (3,4) (4,3) (4,5) (5,4);

# Request types
set Types := m1 m2 m3 m4;

# Zones
set Z := z1 z2 z3 z4;

# Requests (example, you may need to adjust based on your specific requirements)
set R := r1 r2 r3 r4 r5;

# Paths for each request (example, adjust as needed)
set P[r1] := p1 p2 p3;
set P[r2] := p1 p2 p3;
set P[r3] := p1 p2 p3;
set P[r4] := p1 p2 p3;
set P[r5] := p1 p2 p3;

# Links in each path (example, adjust as needed)
set LinksInPath[r1,p1] := (1,2);
set LinksInPath[r1,p2] := (1,4) (4,3);
set LinksInPath[r1,p3] := (1,4) (4,5) (5,2);

set LinksInPath[r2,p1] := (2,5);
set LinksInPath[r2,p2] := (2,1) (1,4) (4,5);
set LinksInPath[r2,p3] := (2,3) (3,4) (4,5);

set LinksInPath[r3,p1] := (2,3);
set LinksInPath[r3,p2] := (2,1) (1,4) (4,3);
set LinksInPath[r3,p3] := (2,1) (1,4) (4,5);

set LinksInPath[r4,p1] := (1,2) (2,5);
set LinksInPath[r4,p2] := (1,4) (4,5);
set LinksInPath[r4,p3] := (1,4) (4,3) (3,2) (2,5);

set LinksInPath[r5,p1] := (3,4);
set LinksInPath[r5,p2] := (3,2) (2,5) (5,4);
set LinksInPath[r5,p3] := (3,2) (2,1) (1,4);

# Possible starting slots for each request (example, adjust as needed)
set C[r1] := 1 3 5 7 9 11 13 15 17 19;
set C[r2] := 21 23 25 27 29 31 33 35 37 39 41 43 45 47 49;
set C[r3] := 51 55 59 63 67 71 75 79 83 87;
set C[r4] := 91 96 101 106 111 116 121 126 131 136;
set C[r5] := 21 23 25 27 29 31 33 35 37 39 41 43 45 47 49;

# Global parameters
param B := 140;  # Total slots per link

# Slot requirements for each type
param slot_req := 
    m1 2
    m2 3
    m3 4
    m4 5;

# Request types (example, adjust as needed)
param type := 
    r1 m1
    r2 m2
    r3 m3
    r4 m4
    r5 m2;

# Zone types
param zone_type :=
    z1 m1
    z2 m2
    z3 m3
    z4 m4;

# Zone capacities
param zone_capacity :=
    z1 20
    z2 30
    z3 40
    z4 50;

end;
