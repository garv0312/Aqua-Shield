-- OPTIONAL: demo technicians and demo leads so the admin dashboard is not empty. Run after schema.sql. All values are DEMO.
insert into technicians(name,mobile,city,areas) values
 ('Ramesh Yadav (DEMO)','9000000101','Bhopal','Arera Colony, MP Nagar'),('Imran Khan (DEMO)','9000000102','Bhopal','Kolar Road, Shahpura'),('Suresh Patel (DEMO)','9000000103','Bhopal','Hoshangabad Road, Piplani');
insert into leads(name,mobile,city,pincode,address,service,leakage_type,property_type,status,follow_up_at,lost_reason,technician_id,inspection_at,created_at) values
 ('Anita Sharma (DEMO)','9000000001','Bhopal','462016','DEMO 12 Arera Colony','bathroom','Bathroom leakage','Apartment / Flat','new',null,null,null,null,now()),
 ('Vikram Singh (DEMO)','9000000002','Bhopal','462011','DEMO 45 Kolar Road','terrace','Terrace / roof seepage','House / Villa','new',null,null,null,null,now()),
 ('Pooja Jain (DEMO)','9000000003','Bhopal','462003','DEMO 7 MP Nagar Zone 1','basement','Basement seepage','Shop / Office','assigned',null,null,(select id from technicians where name like 'Ramesh%'),now()+interval '1 day',now()-interval '2 days'),
 ('Rohit Gupta (DEMO)','9000000004','Bhopal','462026','DEMO 90 Shahpura','terrace','Terrace / roof seepage','House / Villa','inspected',current_date,null,(select id from technicians where name like 'Imran%'),now()-interval '3 days',now()-interval '5 days'),
 ('Sanjay Mishra (DEMO)','9000000006','Bhopal','462022','DEMO 3 Piplani','tank','Water tank leakage','Industrial / Warehouse','follow_up',current_date-1,null,(select id from technicians where name like 'Suresh%'),now()-interval '10 days',now()-interval '12 days'),
 ('Kavita Rao (DEMO)','9000000007','Bhopal','462030','DEMO 18 Katara Hills','pu','Cracks / joints','House / Villa','lost',null,'Price too high',null,null,now()-interval '15 days');
