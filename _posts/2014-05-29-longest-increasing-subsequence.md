---
layout: post
title: "Longest Increasing Subsequence Review"
categories: algorithms
---

Let A[1...n] be a sequence of distinct integers. An increasing subsequence (IS) of A is a subsequence A[i1], A[i2], ..., A[ik], with i1 < i2 < ... < ik, such that, for is < it, we have A[is] < A[it].  A longest increasing subsequence (LIS) of A is an increasing subsequence of maximum length.

__Problem: Find the length of LIS of A__

We start with a solution using dynamic programming.

```
let F[i] be the length of LIS of A[1...i].
let G[i] be the maximum length of IS ending with A[i].
```

Then we have the following state-transition equations:

```
G[i] = max{ G[j] + 1 } for all 1 <= j < i with A[i] > A[j]
       or 1 if such a j does not exist
 
F[i] = max{ G[j] } for all 1 <= j <= i
```

It is obvious that the running time of this algorithm is O(n^2).

Can we do better? Definitely!

Let B[i] be the last element of a minimum LIS of length i. A minimum LIS of length i here refers to a LIS which has smallest ending element among all LISes of length i.

We have B[i] < B[i+1] for all 1 <= i < n. (proof by contradiction)

```
// initialize B
for i from 1 to n
  B[i] = nil

// calculate B
for i from 1 to n
  if there's such a j with 1 <= j < i-1 and B[j] < A[i] < B[j+1]
    B[j+1] = A[i]
  else if A[i] < B[1]
    B[1] = A[i]
  else if A[i] > B[i-1]
    B[i] = A[i]

// find the answer
len = 1
for i from n downto 1
  if B[i] is not nil
    len = i
    break

// then len holds the length of LIS of A.
```

Using this algorithm, we can find the length of LIS of A in running time of O(nlgn).  

### Discussion 

> What if A has duplicate elements ? 

The two algorithms above are also correct for solving this case.

> What if we want to find the length of longest non-decreasing subsequence of a sequence which may have duplicate elements ? 

It is trival to modify the first algorithm to solve this problem, we only need to change transition equation of G[i] to:

```
G[i] = max{ G[j] + 1 } for all 1 <= j < i with A[i] >= A[j]
       or 1 if such a j does not exist
 
```   

For the second algorithm, we have property B[i] <= B[i+1] instead of B[i] < B[i+1] in this case. And the calculating process of B should be modified.

```
// calculate B
for i from 1 to n
  if there's such a j with 1 <= j < i-1 and B[j] <= A[i] < B[j+1]
    B[j+1] = A[i]
  else if A[i] < B[1]
    B[1] = A[i]
  else if A[i] >= B[i-1]
    B[i] = A[i]

```   
   
