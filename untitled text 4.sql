/*1. Build a query to count the number of loans per customer.*/
select custid,count(distinct loanid) from all_loans group by custid

/*2. Write a query to identify if a customer had more than one loan at
the same time.
# Note:Not sure if I understand "at the same time"correctly.My logic is that for two or more loans to exist at the same time, 
# we need to find the ones that neither being written off nor being payoff as of the date we run the code. If someone has loan1
that was being paid off on 01/09/2019 and get a loan2 on 01/10/2019 then our SQL code should return 0 for this client since he
did not have more than one loan at the same time*/
select custid, case when temp.loan_count >1 then 1 else 0 end as loan_flag
from (select custid,count(distinct loanid) as loan_count from all_loans where payoffdate is  null and writeoffdate is  null 
group by custid)temp

/*3a. Write a query to calculate how much payment is received from each
customer in the 1st 6 months of them being a customer
(across loans, if multiple loans are taken within their 1st 6 months).*/
/* First, get the first approdate as first date of being a customer for each customer, call this new table table c.Then
join the two existing tables and this new table c, narrow it down to the ones meet the 6 months criteria, lastly group by
custid and sum up amount paid*/
select a.custid,  sum(b.amount_paid) from all_loans a left join all_loanhist b 
on a.loanid=b.loanid 
inner join (select custid, min(approvedate) as first_date from all_loans group by custid ) c 
on a.custid=c.custid 
where b.eowdate between c.first_date and DATEADD(month, 6, c.first_date)
group by a.custid

/*3b. Also provide what % of principal was collected in the 1st 6 months
from the customer*/
/* Same as previous question, get a new temp table c restore everyone's first date,join it with two existing tables, then sum
up principal_paid for each loan and each customer if they took place before 6 months after first date being a customer, call
such table table temp. On the other hand,get the total loan amount for each loan from all_loans and call it temp2. Join temp1
and temp2 together,making sure loanid=loanid and custid=custid, then use principal_paid from temp divided by amount from temp2*/
select temp.custid, sum(temp.principal_paid)/sum(temp2.amount)
from(select a.loanid, a.custid, sum(principal_paid)as principal_paid from all_loans a left join all_loanhist b 
on a.loanid=b.loanid 
inner join (select custid, min(approvedate) as first_date from all_loans group by custid ) c
on a.custid=c.custid 
where b.eowdate between c.first_date and DATEADD(month, 6, c.first_date)
group by a.loanid,a.custid)temp,all_loans temp2
where temp.loanid=temp2.loanid and temp.custid=temp2.custid
group by temp.custid


/*4. Calculate the average rate of missing 1st payment by month of
approvedate of loan.*/
/*Note:Not sure this questions is asking at the customer level or loan level. So I used this loan level formula 
number of loan missed 1st payment period/total number of loans. And I assumed that if someone missed a payment then amount_paid for that 
week is null.
First, get the min date after approvedate as first_pay_date.Join this table with two existing tables,making sure we only kept the ones has null value for amount_paid on the 
first_pay_date.On the other hand, get the number of loan by the month and year of approvedate as the denominator for our formula. Lasly, calculate the percentage rate group by 
month and year of appovedate */
select temp.loan_year,temp.loan_month, temp.number_of_missed_loan/temp2.number_of_loans
from 
(select year(a.approvedate) as loan_year ,month(a.approvedate) as loan_month,count(*) as number_of_missed_loan from all_loans a
left join all_loanhist b 
on a.loanid=b.loanid inner join
(select loanid,min(eowdate) as first_pay_date from all_loanhist group by loanid)c
on a.loanid=c.loanid
where b.eowdate=c.first_pay_date and b.amount_paid is null
group by year(a.approvedate),month(a.approvedate)
) temp,
(select year(approvedate) as loan_year ,month(approvedate)as loan_month,count (distinct loanid ) as number_of_loans 
from all_loans group by year(approvedate),month(approvedate))temp2
where temp.loan_year=temp2.loan_year and temp.loan_month=temp2.loan_month 

/*5. Calculate the top 3 most profitable customers in the tables. Profitability is
defined as percentage of total paid of loan amount.*/
/* Method 1:assume ties does not matter and we only want three customers that has highest profitability*/
select temp1.custid, temp1.total_paid/temp2.total_amount as profitability from
(select a.custid, sum(b.amount_paid)as total_paid from all_loans a left join all_loanhist b 
on a.loanid=b.loanid  group by a.custid) temp1,
(select custid, sum(amount) as total_amount from all_loans  group by custid)temp2
where temp1.custid=temp2.custid
order by 2 desc
limit 3

/* Method 2:assume ties does matter and we want top 3 highest profitability even this returns back more than 3 customers*/
select temp3.custid from(select temp1.custid, dense_rank()over(order by temp1.total_paid/temp2.total_amount)as rnk from
(select a.custid, sum(b.amount_paid)as total_paid from all_loans a left join all_loanhist b 
on a.loanid=b.loanid  group by a.custid) temp1,
(select custid, sum(amount) as total_amount from all_loans  group by custid)temp2
where temp1.custid=temp2.custid)temp3
where rnk in (1,2,3)
