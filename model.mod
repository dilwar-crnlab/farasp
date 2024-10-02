# Optical Network Resource Allocation Model

###############################################################################
#                                 MODEL SECTION                                 #
###############################################################################

# Sets
set N;                    # Set of nodes
set L within {N, N};      # Set of links (defined as node pairs)
set R;                    # Set of requests
set Types;                # Set of request types (e.g., m1, m2, m3, m4)
set Z;                    # Set of zones
set P{R};                 # Set of paths for each request
set C{R};                 # Set of possible starting slots for each request
set LinksInPath{r in R, p in P[r]} within L;  # Links in each path

# Parameters
param B >= 0, integer;    # Total number of spectrum slots per link
param K >= 0, integer;    # Maximum number of simultaneous channels per zone

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

###############################################################################
#                                 DATA SECTION                                  #
###############################################################################

data;

# Network topology
set N := 1 2 3 4 5;
set L := (1,2) (1,4) (2,3) (2,5) (3,4) (4,5);

# Request types
set Types := m1 m2 m3 m4;

# Zones
set Z := z1 z2 z3 z4;

# Requests
set R := r1 r2 r3 r4 r5;

# Paths for each request
set P[r1] := p1 p2;
set P[r2] := p1 p3;
set P[r3] := p2 p4;
set P[r4] := p1 p3;
set P[r5] := p2 p4;

# Links in each path
set LinksInPath[r1,p1] := (1,2) (2,3);
set LinksInPath[r1,p2] := (1,4) (3,4);
set LinksInPath[r2,p1] := (2,5);
set LinksInPath[r2,p3] := (1,2) (4,5);
set LinksInPath[r3,p2] := (2,3);
set LinksInPath[r3,p4] := (4,5);
set LinksInPath[r4,p1] := (1,2);
set LinksInPath[r4,p3] := (2,5);
set LinksInPath[r5,p2] := (3,4);
set LinksInPath[r5,p4] := (1,4);

# Possible starting slots for each request
set C[r1] := 1 2 3;
set C[r2] := 1 4 7;
set C[r3] := 3 5 8;
set C[r4] := 2 4 6;
set C[r5] := 1 3 5;

# Global parameters
param B := 360;  # Total slots per link
param K := 10;   # Max channels per zone

# Slot requirements for each type
param slot_req := 
    m1 2
    m2 3
    m3 4
    m4 5;

# Request types
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
    z1 10
    z2 30
    z3 40
    z4 50;

end;

solve;

printf "\n=================================================================\n";
printf "                        SOLUTION SUMMARY                           \n";
printf "=================================================================\n\n";

# 1. Overall Statistics
printf "OVERALL STATISTICS:\n";
printf "-------------------\n";
printf "Total requests: %d\n", card(R);
printf "Accepted requests: %d\n", sum{r in R} a[r];
printf "Acceptance rate: %.2f%%\n\n", 100 * sum{r in R} a[r] / card(R);

# 2. Accepted Requests Detail
printf "ACCEPTED REQUESTS:\n";
printf "-----------------\n";
for {r in R: a[r] = 1} {
    printf "Request %s:\n", r;
    printf "  Type: %s (requires %d slots)\n", type[r], slot_req[type[r]];
    
    # Print assigned path
    for {p in P[r]: x[r,p] = 1} {
        printf "  Path: %s\n", p;
        printf "  Links: ";
        for {(i,j) in LinksInPath[r,p]} {
            printf "(%d,%d) ", i, j;
        }
        printf "\n";
    }
    
    # Print assigned slots
    for {s in C[r]: y[r,s] = 1} {
        printf "  Starting slot: %d\n", s;
        printf "  Allocated slots: %d to %d\n", 
               s, s + slot_req[type[r]] - 1;
    }
    printf "\n";
}

# 3. Rejected Requests
printf "REJECTED REQUESTS:\n";
printf "-----------------\n";
for {r in R: a[r] = 0} {
    printf "Request %s (Type %s)\n", r, type[r];
}
printf "\n";

# 4. Zone Utilization
printf "ZONE UTILIZATION:\n";
printf "----------------\n";
for {z in Z} {
    printf "Zone %s (Type %s):\n", z, zone_type[z];
    for {(i,j) in L} {
        let used_slots := sum{r in R, p in P[r], s in C[r]: 
            (i,j) in LinksInPath[r,p] and 
            zone_type[z] = type[r] and 
            a[r] = 1} z_alloc[r,s];
        if used_slots > 0 then {
            printf "  Link (%d,%d): %d slots used out of %d capacity\n", 
                   i, j, used_slots, zone_capacity[z];
        }
    }
    printf "\n";
}

# 5. Link Utilization
printf "LINK UTILIZATION:\n";
printf "----------------\n";
for {(i,j) in L} {
    let total_used := sum{r in R, p in P[r], s in C[r]: 
        (i,j) in LinksInPath[r,p] and a[r] = 1} z_alloc[r,s];
    printf "Link (%d,%d): %d slots used out of %d total\n", 
           i, j, total_used, B;
}
printf "\n";

# 6. Computation Statistics
printf "COMPUTATION STATISTICS:\n";
printf "----------------------\n";
printf "Solving time: %.2f seconds\n", _solve_time;
printf "Objective value: %d\n", Total_Accepted;

printf "\n=================================================================\n";
