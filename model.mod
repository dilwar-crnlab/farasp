# Elastic Optical Network Spectrum Allocation in GLPK

set N;          # Set of nodes
set E within N cross N;  # Set of links (edges)
set D;          # Set of demands
set S;          # Set of spectrum slots
param f{D};     # Required frequency slots for each demand
param s_d{D};   # Source node of demand d
param t_d{D};   # Target node of demand d
param delta{E}; # Length or cost of each link
param M_d;      # Maximum number of paths for each demand

# Decision variables
var x{d in D, p in 1..M_d, (i,j) in E}, binary;  # 1 if demand d uses link (i,j) on path p, 0 otherwise
var y{d in D, p in 1..M_d, s in S, (i,j) in E}, binary;  # 1 if demand d uses slot s on link (i,j) in path p
var z{d in D, p in 1..M_d, s in S}, binary;      # 1 if demand d uses slot s in path p

# Objective: Minimize total spectrum usage across all demands
minimize TotalSpectrumUsage:
    sum{d in D, p in 1..M_d, s in S} z[d,p,s];

# Constraints

# Flow conservation: Ensure demand flows from source to target
s.t. FlowConservation_Source{d in D}:
    sum{p in 1..M_d, (i,j) in E: i = s_d[d]} x[d,p,(i,j)] - sum{p in 1..M_d, (j,i) in E: i = s_d[d]} x[d,p,(j,i)] = 1;

s.t. FlowConservation_Target{d in D}:
    sum{p in 1..M_d, (i,j) in E: j = t_d[d]} x[d,p,(i,j)] - sum{p in 1..M_d, (i,j) in E: i = t_d[d]} x[d,p,(i,j)] = -1;

s.t. FlowConservation_Intermediate{d in D, i in N: i != s_d[d] and i != t_d[d]}:
    sum{p in 1..M_d, (i,j) in E} x[d,p,(i,j)] - sum{p in 1..M_d, (j,i) in E} x[d,p,(j,i)] = 0;

# Spectrum continuity: Slots must be the same across all links in the path
s.t. SpectrumContinuity{d in D, p in 1..M_d, s in S, (i,j) in E, (j,k) in E}:
    y[d,p,s,(i,j)] = y[d,p,s,(j,k)];

# Spectrum contiguity: Slots must be contiguous for each demand
s.t. SpectrumContiguity{d in D, p in 1..M_d, s in 2..card(S), (i,j) in E}:
    y[d,p,s,(i,j)] - y[d,p,s-1,(i,j)] >= 0;

# Non-overlapping constraint: Each slot on each link can only be used by one demand at a time
s.t. NonOverlapping{(i,j) in E, s in S}:
    sum{d in D, p in 1..M_d} y[d,p,s,(i,j)] <= 1;

# Frequency slot allocation: Ensure each demand gets the required number of slots
s.t. SlotAllocation{d in D}:
    sum{s in 1..card(S)-f[d]+1, p in 1..M_d} z[d,p,s] = f[d];

# Path assignment: Only one path is assigned to each demand
s.t. PathAssignment{d in D, p in 1..M_d, (i,j) in E}:
    x[d,p,(i,j)] <= 1;

# Spectrum slot usage: Relating slot usage on path to slot usage on each link
s.t. SpectrumUsage_Path_Link{d in D, p in 1..M_d, s in S, (i,j) in E}:
    z[d,p,s] >= y[d,p,s,(i,j)];

# Solve
solve;

# Output results
printf "Demand allocation results:\n";
for {d in D} {
    printf "Demand %s:\n", d;
    for {p in 1..M_d, s in S} {
        if z[d,p,s] = 1 then
            printf "   Path %d uses slot %s\n", p, s;
    }
}

end;
