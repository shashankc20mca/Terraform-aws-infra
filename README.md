Internet -=------>
 [IGW]
  ----------->
 [ALB SG: 80/443 from 0.0.0.0/0]
  ----------->
[Public Subnet-1 or Public Subnet-2]  -------->



  ++++++++ TargetGroup:80 --> Web EC2-1 (Public Subnet-1)

(OR)

  ++++++++ TargetGroup:80 --> Web EC2-2 (Public Subnet-2)

Public EC2:
- Inbound 80 ONLY from ALB SG
- (Optional) 22 ONLY from Bastion SG

Bastion EC2:
- SSH 22 only from YOUR_PUBLIC_IP/32

Private EC2:
- SSH 22 only from Bastion SG
- Outbound internet via NAT GW (in Public Subnet-1)
