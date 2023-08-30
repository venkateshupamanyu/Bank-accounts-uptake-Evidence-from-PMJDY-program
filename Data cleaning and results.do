

use "...\data.dta"


******************************************************************************************************************************************************
*** Dropping branches for creating state specific files ***
******************************************************************************************************************************************************
*** creating only Karnataka ***
drop if inlist(branch,"Ghatkesar","Kanchipuram","Servanampatty","Siddipet","Sivrampalli","Tandur","Vikarabad","Zaheerabad")
tab branch

*** creating only Telangana ***
drop if inlist(branch,"ADB Gangavati","ADB Sindhanur","Gangavati MB","Kanchipuram","Servanampatty")
tab branch

*** creating only Tamilnadu ***
drop if inlist(branch,"ADB Gangavati","ADB Sindhanur","Gangavati MB","Ghatkesar","Siddipet","Sivrampalli","Tandur","Vikarabad","Zaheerabad")
tab branch

drop if age_quarter>7

drop if age_quarter>8
unique account
unique account if pmjdy==1
unique account if pmjdy==0
unique account if zero_balance==1
unique account if pmjdy==1 & zero_balance==1
unique account if pmjdy==0 & zero_balance==1
unique account if pmjdy==.

unique account if age_quarter<9
unique account if pmjdy==1 & age_quarter<9
unique account if pmjdy==0 & age_quarter<9
unique account if zero_balance==1 & age_quarter<9
unique account if pmjdy==1 & zero_balance==1 & age_quarter<9
unique account if pmjdy==0 & zero_balance==1 & age_quarter<9
unique account if pmjdy==. & age_quarter<9

******************************************************************************************************************************************************
*** Demon code ***
******************************************************************************************************************************************************
gen max_date = 0
encode branch, gen(branch_code)
replace max_date = mdy(03,15,2017) if branch_code == 1 & new_data == 1 // ADB Gangavathi
replace max_date = mdy(03,17,2017) if branch_code == 2 & new_data == 1 // ADB Sindhanur
replace max_date = mdy(03,16,2017) if branch_code == 3 & new_data == 1 // Gangavathi MB
replace max_date = mdy(01,24,2017) if branch_code == 4 & new_data == 1 // Ghatkesar
replace max_date = mdy(03,22,2017) if branch_code == 5 & new_data == 1 // Kanchipuram
replace max_date = mdy(03,24,2017) if branch_code == 6 & new_data == 1 // Sarvanampatti
replace max_date = mdy(02,09,2017) if branch_code == 7 & new_data == 1 // Siddipet
replace max_date = mdy(09,18,2016) if branch_code == 8 & new_data == 1 // Sivrampalli
replace max_date = mdy(02,18,2017) if branch_code == 9 & new_data == 1 // Tandur
replace max_date = mdy(03,3,2017)  if branch_code == 11 & new_data == 1 // Zaheerabad
replace max_date = mdy(07,15,2016) if branch_code == 4 & new_data == 0 // Ghatkesar
replace max_date = mdy(11,08,2016) if branch_code == 7 & new_data == 0 // Siddipet
replace max_date = mdy(11,02,2016) if branch_code == 9 & new_data == 0 // Tandur
replace max_date = mdy(11,03,2016) if branch_code == 10 & new_data == 0 // Vikarabad

gen max_date_demon = cond(new_data==1 & max_date>mdy(11,08,2016), mdy(11,08,2016),max_date)
drop if date >= max_date_demon

//gen min_date = acct_open_v2
format date max_date max_date_demon %td //min_date
gen open_date = cond(open_date_s1 !=.,open_date_s1,cond(open_date_s2 != .,open_date_s2, first_trans_date))

// dropping 
count if open_date == . // 373 zero balance accounts for which open dates are known
count if open_date == . & zero == 1
count if open_date == . & pmjdy // 1 zero balance account 
count if open_date == . & pmjdy==0 // 372 zero balance accounts with no information about starting date
//drop if open_date == . // around 10 % of the accounts are zero balance and others

drop if open_date > max_date
bysort account : egen min_date = min(date)
format %td min_date
count if min_date <open_date
replace open_date = min_date if min_date < open_date

**Generating account age**
bysort account (date): gen age = cond(date==.,open_date,date) - open_date
gen age_quarter = floor(age/90)+1
gen max_length = max_date_demon - open_date // accounts for zero balance
bysort account : egen min_age_account = min(age) 

gen age_week = floor(age/7)+1
gen age_month = floor(age/30)+1

gen max_month = floor(max_length/30)+1
gen max_quarter = floor(max_length/90)+1
gen min_month = floor(min_age_account/30)+1
gen min_quarter = floor(min_age_account/90)+1

bysort account age_quarter : egen quarter_govt_assisted = max(govt_init_trans)
bysort account age_month : egen month_govt_assisted = max(govt_init_trans)


******************************************************************************************************************************************************
*** Summary stats ***
******************************************************************************************************************************************************
use "...\data.dta"
use "......\data_savings - version 2.dta"


******************************************************************************************************************************************************
*** Balance movement for graph  - quarterly last balance ***
******************************************************************************************************************************************************
*** run line 27 to 57 from balance_analysis_v2.do - runs monthly last balance code ***
*** after above code, run line 69 from balance_analysis_v2_control.do - gives balance quarter-wise ***
** Quarter last balance
*** first set ***
	bysort account age_month (date) : gen rank = _n
	bysort account age_month (date) : gen rank_max = _N
	keep if rank == rank_max

	gen c = 1
	sort branch account age_month
	order branch account age_month
	collapse (sum) balance (mean) min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_quarter pmjdy)
//	collapse (mean) balance  min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_quarter pmjdy)
	// filling the space
	tsset account age_quarter
	tsfill, full
	bysort account (age_quarter) : carryforward branch pmjdy min_quarter max_quarter open_date, replace
	//br if branch == ""
	gsort account -age_quarter
	bysort account : carryforward branch pmjdy max_quarter min_quarter open_date, replace
	recode quarter_govt_assisted (.=0)
	drop if min_quarter>1 & pmjdy == 0 // dropped if minimum month is greater than 1
	keep if age_quarter<=max_quarter
	gen age_days = 90*age_quarter
	gen date = open_date + age_days
	format %td date
	gen quarter_date = quarter(date)
	gen quarter_year = year(date)*100+quarter(date)
	gen month_year = year(date)*100+month(date)
	gen month_date = month(date)
	gen year_date = year(date)
	encode branch, gen(branch_code)

	gen ln_bal = log(1+balance)
	label var ln_bal "Log(1+Balance)"

	bysort account (age_quarter) : gen quarter_govt_assisted_1 = quarter_govt_assisted[_n-1]
	recode quarter_govt_assisted_1 (.=0)
	gen t_t_1_govt = (quarter_govt_assisted_1==quarter_govt_assisted)
	replace t_t_1_govt=0 if quarter_govt_assisted==0
	global controls "t_t_1_govt"
*** first set ***
	
*** second set ***
	bysort pmjdy: tabstat balance if age_quarter <=8, by(age_quarter) col(stat) statistics(mean p50)
	bysort pmjdy: tabstat ln_bal if age_quarter <=8, by(age_quarter) col(stat) statistics(mean p50)
*** second set ***
******************************************************************************************************************************************************
*** Balance movement for graph  - quarterly last balance ***
******************************************************************************************************************************************************

******************************************************************************************************************************************************
*** d_q distribution work ***
******************************************************************************************************************************************************
*** first_trans may not be correct always for all accounts ***

gen state="Karnataka" if inlist(branch,"ADB Gangavati","ADB Sindhanur","Gangavati MB")
replace state="Telangana" if inlist(branch,"Ghatkesar","Siddipet","Sivrampalli","Tandur","Vikarabad","Zaheerabad")
replace state="Tamilnadu" if inlist(branch,"Kanchipuram","Servanampatty")

egen state_id=group(state)

sort account age_quarter
by account: egen min_age_quarter=min(age_quarter)

egen tag=tag(age_quarter)

*** active transactions ***
unique account if zero_balance==0 & COMBINE==1 & min_age_quarter==1 & state_id==3
unique account if zero_balance==0 & COMBINE==1 & min_age_quarter==2 & state_id==3
unique account if zero_balance==0 & COMBINE==1 & min_age_quarter==3 & state_id==3
unique account if zero_balance==0 & COMBINE==1 & min_age_quarter==4 & state_id==3
unique account if zero_balance==0 & COMBINE==1 & min_age_quarter==5 & state_id==3
unique account if zero_balance==0 & COMBINE==1 & min_age_quarter==6 & state_id==3
unique account if zero_balance==0 & COMBINE==1 & min_age_quarter==7 & state_id==3
unique account if zero_balance==0 & COMBINE==1 & min_age_quarter==8 & state_id==3

unique account if COMBINE==1 & min_age_quarter==1
unique account if COMBINE==1 & min_age_quarter==2
unique account if COMBINE==1 & min_age_quarter==3
unique account if COMBINE==1 & min_age_quarter==4
unique account if COMBINE==1 & min_age_quarter==5
unique account if COMBINE==1 & min_age_quarter==6
unique account if COMBINE==1 & min_age_quarter==7
unique account if COMBINE==1 & min_age_quarter==8
unique account if COMBINESUM==0

unique account if COMBINESUM==0 & state_id==1 & pmjdy==.
unique account if COMBINESUM==0 & state_id==2 & pmjdy==.
unique account if COMBINESUM==0 & state_id==3 & pmjdy==.

sort min_age_quarter
by min_age_quarter: distinct account if COMBINE==1

*** pmjdy accounts ***
unique account if COMBINE==1 & pmjdy==1 & min_age_quarter==1
unique account if COMBINE==1 & pmjdy==1 & min_age_quarter==2
unique account if COMBINE==1 & pmjdy==1 & min_age_quarter==3
unique account if COMBINE==1 & pmjdy==1 & min_age_quarter==4
unique account if COMBINE==1 & pmjdy==1 & min_age_quarter==5
unique account if COMBINE==1 & pmjdy==1 & min_age_quarter==6
unique account if COMBINE==1 & pmjdy==1 & min_age_quarter==7
unique account if COMBINE==1 & pmjdy==1 & min_age_quarter==8
unique account if COMBINESUM==0 & pmjdy==1
unique account if COMBINESUM==0 & pmjdy==0
unique account if COMBINESUM==0 & pmjdy==.


unique account if zero_balance==0 & COMBINE==1 & pmjdy==. & min_age_quarter==1 & state_id==1
unique account if zero_balance==0 & COMBINE==1 & pmjdy==. & min_age_quarter==2 & state_id==1
unique account if zero_balance==0 & COMBINE==1 & pmjdy==. & min_age_quarter==3 & state_id==1
unique account if zero_balance==0 & COMBINE==1 & pmjdy==. & min_age_quarter==4 & state_id==1
unique account if zero_balance==0 & COMBINE==1 & pmjdy==. & min_age_quarter==5 & state_id==1
unique account if zero_balance==0 & COMBINE==1 & pmjdy==. & min_age_quarter==6 & state_id==1
unique account if zero_balance==0 & COMBINE==1 & pmjdy==. & min_age_quarter==7 & state_id==1
unique account if zero_balance==0 & COMBINE==1 & pmjdy==. & min_age_quarter==8 & state_id==1


sort min_age_quarter
by min_age_quarter: distinct account if COMBINE==1 & pmjdy==1

*** non-pmjdy accounts ***
unique account if COMBINE==1 & pmjdy==0 & min_age_quarter==1
unique account if COMBINE==1 & pmjdy==0 & min_age_quarter==2
unique account if COMBINE==1 & pmjdy==0 & min_age_quarter==3
unique account if COMBINE==1 & pmjdy==0 & min_age_quarter==4
unique account if COMBINE==1 & pmjdy==0 & min_age_quarter==5
unique account if COMBINE==1 & pmjdy==0 & min_age_quarter==6
unique account if COMBINE==1 & pmjdy==0 & min_age_quarter==7
unique account if COMBINE==1 & pmjdy==0 & min_age_quarter==8

sort min_age_quarter
by min_age_quarter: distinct account if COMBINE==1 & pmjdy==0

*** unclassified accounts ***
unique account if COMBINE==1 & pmjdy==. & min_age_quarter==1
unique account if COMBINE==1 & pmjdy==. & min_age_quarter==2
unique account if COMBINE==1 & pmjdy==. & min_age_quarter==3
unique account if COMBINE==1 & pmjdy==. & min_age_quarter==4
unique account if COMBINE==1 & pmjdy==. & min_age_quarter==5
unique account if COMBINE==1 & pmjdy==. & min_age_quarter==6
unique account if COMBINE==1 & pmjdy==. & min_age_quarter==7
unique account if COMBINE==1 & pmjdy==. & min_age_quarter==8

sort min_age_quarter
by min_age_quarter: distinct account if COMBINE==1 & pmjdy==.


*** non-active transactions ***
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==1
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==2
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==3
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==4
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==5
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==6
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==7
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==8

unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1 | unexplained==1) & min_age_quarter==1
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1 | unexplained==1) & min_age_quarter==2
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1 | unexplained==1) & min_age_quarter==3
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1 | unexplained==1) & min_age_quarter==4
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1 | unexplained==1) & min_age_quarter==5
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1 | unexplained==1) & min_age_quarter==6
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1 | unexplained==1) & min_age_quarter==7
unique account if (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1 | unexplained==1) & min_age_quarter==8


sort min_age_quarter
by min_age_quarter: distinct account if ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1


*** for accounts that have transactions in all 8 quarters ***
egen tag=tag(account age_quarter)
egen tagtotal=total(tag), by(account)
tab tagtotal

*** active transactions ***
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==1
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==2
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==4
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==5
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==6
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==7
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==8

unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==1 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==2 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==3 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==4 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==5 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==6 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==7 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & min_age_quarter==8 & state_id==3


unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==1 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==2 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==3 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==4 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==5 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==6 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==7 & state_id==3
unique account if zero_balance==0 & tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==8 & state_id==3

unique account if tagtotal==8 & COMBINE==1 & min_age_quarter==2
unique account if tagtotal==8 & COMBINE==1 & min_age_quarter==3
unique account if tagtotal==8 & COMBINE==1 & min_age_quarter==4
unique account if tagtotal==8 & COMBINE==1 & min_age_quarter==5
unique account if tagtotal==8 & COMBINE==1 & min_age_quarter==6
unique account if tagtotal==8 & COMBINE==1 & min_age_quarter==7
unique account if tagtotal==8 & COMBINE==1 & min_age_quarter==8

sort min_age_quarter
by min_age_quarter: distinct account if tagtotal==8 & COMBINE==1

*** pmjdy accounts ***
unique account if tagtotal==8 & COMBINE==1 & pmjdy==1 & min_age_quarter==1
unique account if tagtotal==8 & COMBINE==1 & pmjdy==1 & min_age_quarter==2
unique account if tagtotal==8 & COMBINE==1 & pmjdy==1 & min_age_quarter==3
unique account if tagtotal==8 & COMBINE==1 & pmjdy==1 & min_age_quarter==4
unique account if tagtotal==8 & COMBINE==1 & pmjdy==1 & min_age_quarter==5
unique account if tagtotal==8 & COMBINE==1 & pmjdy==1 & min_age_quarter==6
unique account if tagtotal==8 & COMBINE==1 & pmjdy==1 & min_age_quarter==7
unique account if tagtotal==8 & COMBINE==1 & pmjdy==1 & min_age_quarter==8

sort min_age_quarter
by min_age_quarter: distinct account if tagtotal==8 & COMBINE==1 & pmjdy==1

*** non-pmjdy accounts ***
unique account if tagtotal==8 & COMBINE==1 & pmjdy==0 & min_age_quarter==1
unique account if tagtotal==8 & COMBINE==1 & pmjdy==0 & min_age_quarter==2
unique account if tagtotal==8 & COMBINE==1 & pmjdy==0 & min_age_quarter==3
unique account if tagtotal==8 & COMBINE==1 & pmjdy==0 & min_age_quarter==4
unique account if tagtotal==8 & COMBINE==1 & pmjdy==0 & min_age_quarter==5
unique account if tagtotal==8 & COMBINE==1 & pmjdy==0 & min_age_quarter==6
unique account if tagtotal==8 & COMBINE==1 & pmjdy==0 & min_age_quarter==7
unique account if tagtotal==8 & COMBINE==1 & pmjdy==0 & min_age_quarter==8

sort min_age_quarter
by min_age_quarter: distinct account if tagtotal==8 & COMBINE==1 & pmjdy==0

*** unclassified accounts ***
unique account if tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==1
unique account if tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==2
unique account if tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==3
unique account if tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==4
unique account if tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==5
unique account if tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==6
unique account if tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==7
unique account if tagtotal==8 & COMBINE==1 & pmjdy==. & min_age_quarter==8

tab min_age_quarter if tagtotal==8

*** non-active transactions ***
unique account if tagtotal==8 & (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==1
unique account if tagtotal==8 & (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==2
unique account if tagtotal==8 & (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==3
unique account if tagtotal==8 & (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==4
unique account if tagtotal==8 & (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==5
unique account if tagtotal==8 & (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==6
unique account if tagtotal==8 & (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==7
unique account if tagtotal==8 & (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1) & min_age_quarter==8

sort min_age_quarter
by min_age_quarter: distinct account if tagtotal==8 & (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1)

unique account if tagtotal==8
unique account if tagtotal==8 & COMBINE==1
unique account if tagtotal==8 & (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1)
unique account if tagtotal==8 & (COMBINE==1 | ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1)
unique account if tagtotal==8 & unexplained==1

unique account if tagtotal==8 & min_age_quarter==1
unique account if tagtotal==8 & COMBINE==1 & min_age_quarter==1
unique account if tagtotal==8 & (ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1 | unexplained==1) & min_age_quarter==1
unique account if tagtotal==8 & (COMBINE==1 | ALL_CHARGES==1 | CRDT_BLK==1 | CRDT_BLK_Others==1 | INTEREST==1 | unexplained==1)  & min_age_quarter==1
unique account if tagtotal==8 & unexplained==1 & min_age_quarter==1















******************************************************************************************************************************************************
*** Table 5 - monthly last balance ***
******************************************************************************************************************************************************
** Quarter last balance
	bysort account age_month (date) : gen rank = _n
	bysort account age_month (date) : gen rank_max = _N
	keep if rank == rank_max

	gen c = 1
	sort branch account age_month
	order branch account age_month
//	collapse (sum) balance (mean) min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_quarter pmjdy)
	collapse (mean) balance  min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_month pmjdy)
	// filling the space
	tsset account age_month
	tsfill, full
	bysort account (age_month) : carryforward branch pmjdy min_quarter max_quarter open_date, replace
	//br if branch == ""
	gsort account -age_month
	bysort account : carryforward branch pmjdy max_quarter min_quarter open_date, replace
	recode quarter_govt_assisted (.=0)
	drop if min_quarter>1 & pmjdy == 0 // dropped if minimum month is greater than 1
	
	gen ln_bal = log(1+balance)
	label var ln_bal "Log(1+Balance)"

	tab age_month
	bysort pmjdy: tabstat balance if age_month <=24, by(age_month) col(stat) statistics(mean p50)
	bysort pmjdy: tabstat ln_bal if age_month <=24, by(age_month) col(stat) statistics(mean p50)
******************************************************************************************************************************************************
*** Table 5 - monthly last balance ***
******************************************************************************************************************************************************

******************************************************************************************************************************************************
*** Table 5 - summary stats ***
******************************************************************************************************************************************************
tab age_quarter
drop if age_quarter>8
tab age_quarter

preserve
keep date pmjdy
restore
*** period of obs ***
tab date
tab date if pmjdy==1
tab date if pmjdy==0
*** no. of accounts ***
distinct account
distinct account if pmjdy == 1
distinct account if pmjdy == 0
distinct account if pmjdy == .
count if pmjdy == 1
count if pmjdy == 0
count if pmjdy == .
*** zero balance ***
unique account if zero_balance==1
unique account if zero_balance==1 & pmjdy==1
unique account if zero_balance==1 & pmjdy==0
*** average & median no. of transactions per account ***
bysort account : gen k = _N
preserve
keep account pmjdy k
duplicates drop
bysort pmjdy : su k, detail
su k, detail
restore
*** average size of transactions ***
bysort account (date1) : egen mean_value = mean(amount)
preserve
keep account pmjdy mean_value COMBINE
duplicates drop
bysort pmjdy : su mean_value, detail
su mean_value, detail
restore
*** end of period balance  ***
*** goto balance_analysis_v2_control.do file and run  ***
*** run from 35 to 70 ***
*** do some changes to get mean and median end of period balance ***
******************************************************************************************************************************************************
*** Table 5 - summary stats  ***
******************************************************************************************************************************************************

******************************************************************************************************************************************************
*** Table 6 ***
******************************************************************************************************************************************************
*** number of transactions ***
bysort pmjdy : su COMBINE ALL_CHARGES CRDT_BLK INTEREST zero unexplained, sep(0)

gen CRDT_BLK_Others = (CRDT_BLK & !LPG_SUBSIDY)
*** all accounts ***
su COMBINE ATM CSH CHQ CR_TRF_ALL DB_TRF_ALL POS PMJJBY PMSBY SAL TDS LIC NPCI ///
	ALL_CHARGES  REPIN AMC_ATM CHARGES INTR_CTY_CHRG  ///
	CRDT_BLK LPG_SUBSIDY CRDT_BLK_Others ///
	INTEREST zero unexplained, sep(0)

*** pmjdy and non-pmjdy accounts ***
bysort pmjdy : su COMBINE ATM CSH CHQ CR_TRF_ALL DB_TRF_ALL POS PMJJBY PMSBY SAL TDS LIC NPCI ///
	ALL_CHARGES  REPIN AMC_ATM CHARGES INTR_CTY_CHRG  ///
	CRDT_BLK LPG_SUBSIDY CRDT_BLK_Others ///
	INTEREST zero unexplained, sep(0)	
	
******************************************************************************************************************************************************
*** Table 6 ***
******************************************************************************************************************************************************

******************************************************************************************************************************************************
*** Table 7 ***
******************************************************************************************************************************************************
 gen active=0
 replace active=1 if ACTIVE_DEP==1 | ACTIVE_WDL==1

*** first set - run from 115 to 129 - from summary.do ***
*** second set - run from 150 to 152 - (without preserve and restore) - from summary.do ***
*** first set ***
	gen c = 1
	sort branch account age_quarter
	order branch account age_quarter
***	collapse (sum) transaction = c value=amount COMBINE ALL_CHARGES CRDT_BLK INTEREST (mean) min_quarter max_quarter (first) open_date, by(account branch age_quarter pmjdy )
***	collapse (sum) transaction = c value=amount COMBINE ALL_CHARGES CRDT_BLK INTEREST (mean) min_quarter max_quarter (first) open_date if govt_assisted_acc==1, by(account branch age_quarter pmjdy )
***	collapse (sum) transaction = c value=amount COMBINE ALL_CHARGES CRDT_BLK INTEREST (mean) min_quarter max_quarter (first) open_date if govt_assisted_acc==0, by(account branch age_quarter pmjdy )
***	collapse (sum) transaction = c value=amount COMBINE ALL_CHARGES CRDT_BLK INTEREST (mean) min_quarter max_quarter (first) open_date if active==1, by(account branch age_quarter pmjdy )
	collapse (sum) transaction = c value=amount COMBINE ALL_CHARGES CRDT_BLK INTEREST (mean) min_quarter max_quarter (first) open_date if active==0, by(account branch age_quarter pmjdy )
	tsset account age_quarter
	tsfill, full
	bysort account (age_quarter) : carryforward branch pmjdy min_quarter max_quarter open_date, replace

	gsort account -age_quarter
	bysort account : carryforward branch pmjdy max_quarter min_quarter open_date, replace
	recode transaction value COMBINE ALL_CHARGES CRDT_BLK INTEREST (.=0)
	drop if min_quarter>1 & pmjdy == 0 // dropped if minimum quarter is greater than 1
	keep if age_quarter<=max_quarter
	drop if age_quarter == 0
*** second set ***
*** please note -- replacing acct_open_v2 with open_date and also doing some changes with that ***
*** collapse (count) account (sum) transaction COMBINE ALL_CHARGES CRDT_BLK INTEREST, by(age_quarter pmjdy)
	collapse (count) account (sum) transaction COMBINE ALL_CHARGES CRDT_BLK INTEREST, by(age_quarter pmjdy)
***	collapse (count) account (sum) transaction COMBINE ALL_CHARGES CRDT_BLK INTEREST if govt_assisted_acc==1, by(age_quarter pmjdy)
	order pmjdy age_quarter
	sort pmjdy age_quarter

******************************************************************************************************************************************************
*** Table 7 ***
******************************************************************************************************************************************************



******************************************************************************************************************************************************
*** demon code ***
use "...\data - before demon code - edit.dta"

drop max_date max_date_demon
drop open_date
drop age
drop age_quarter
drop age_month
drop quarter_govt_assisted
drop month_govt_assisted

drop max_length
drop age_week
drop max_month
drop max_quarter
drop min_month
drop min_quarter




******* copied demon code from mail *******************************************************************************************************************
gen max_date = 0
encode branch, gen(branch_code)
*** encode branch_name, gen(branch_code)
replace max_date = mdy(03,15,2017) if branch_code == 1 & updated_acct == 1 // ADB Gangavathi
replace max_date = mdy(03,17,2017) if branch_code == 2 & updated_acct == 1 // ADB Sindhanur
replace max_date = mdy(03,16,2017) if branch_code == 3 & updated_acct == 1 // Gangavathi MB
replace max_date = mdy(01,24,2017) if branch_code == 4 & updated_acct == 1 // Ghatkesar
replace max_date = mdy(03,22,2017) if branch_code == 5 & updated_acct == 1 // Kanchipuram
replace max_date = mdy(03,24,2017) if branch_code == 6 & updated_acct == 1 // Sarvanampatti
replace max_date = mdy(02,09,2017) if branch_code == 7 & updated_acct == 1 // Siddipet
replace max_date = mdy(09,18,2016) if branch_code == 8 & updated_acct == 1 // Sivrampalli
replace max_date = mdy(02,18,2017) if branch_code == 9 & updated_acct == 1 // Tandur
replace max_date = mdy(03,3,2017) if branch_code == 11 & updated_acct == 1 // Zaheerabad
replace max_date = mdy(07,15,2016) if branch_code == 4 & updated_acct == 0 // Ghatkesar
replace max_date = mdy(11,08,2016) if branch_code == 7 & updated_acct == 0 // Siddipet
replace max_date = mdy(11,02,2016) if branch_code == 9 & updated_acct == 0 // Tandur
replace max_date = mdy(11,03,2016) if branch_code == 10 & updated_acct == 0 // Vikarabad

gen max_date_demon = cond(updated_acct==1 & max_date>mdy(11,08,2016), mdy(11,08,2016),max_date)
// drop if date >= max_date_demon
drop if date >= max_date_demon & zero_balance==0
// dont drop if you want to have zero balance accounts 
//gen min_date = acct_open_v2
format date max_date max_date_demon %td //min_date

gen open_date = cond(open_date_s1 !=.,open_date_s1,cond(open_date_s2 != .,open_date_s2, first_trans_date))

// droping 
count if open_date == . // 373 zero balance accounts for which open dates are known
count if open_date == . & zero == 1
count if open_date == . & pmjdy // 1 zero balance account 
count if open_date == . & pmjdy==0 // 372 zero balance accounts with no information about starting date
//drop if open_date == . // around 10 % of the accounts are zero balance and others

drop if open_date > max_date // this drop deletes 470 obs. of zero balance accounts
bysort account : egen min_date = min(date)
format %td min_date
count if min_date <open_date
replace open_date = min_date if min_date < open_date

**Generating account age**
bysort account (date): gen age = cond(date==.,open_date,date) - open_date
gen age_quarter = floor(age/90)+1
gen max_length = max_date_demon - open_date // accounts for zero balance
bysort account : egen min_age_account = min(age) 

gen age_week = floor(age/7)+1
gen age_month = floor(age/30)+1

gen max_month = floor(max_length/30)+1
gen max_quarter = floor(max_length/90)+1
gen min_month = floor(min_age_account/30)+1
gen min_quarter = floor(min_age_account/90)+1

bysort account age_quarter : egen quarter_govt_assisted = max(govt_init_trans)
bysort account age_month : egen month_govt_assisted = max(govt_init_trans)

******* copied demon code from mail *******************************************************************************************************************

****************************************************************************************************************************************
*** Table 10, 11 - Credit (Active deposits) ***
****************************************************************************************************************************************

forvalues r =1/3{
	use "......\data_savings - version 2 - after demon - without sivarampally.dta", clear
	// dropping zero balance account
	//drop if zero == 1
//		keep if ACTIVE_DEP == 1 
		global cons "ACTIVE_DEP"
		replace amount = cond(ACTIVE_DEP==1,amount,0)
//		keep if pmjdy | SAL_savings
	if (`r' == 1){
		global gov "ALL"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 2){
		keep if govt_assisted_acc == 1
		global gov "GOV"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 3){
		keep if govt_assisted_acc == 0
		global gov "NO_GOV"
		global controls ""
		}

	** All accounts
	gen c = 1
	sort branch account age_month
	order branch account age_month
	collapse (sum) transaction = ACTIVE_DEP value=amount (mean) min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_quarter pmjdy)
	// filling the space
	tsset account age_quarter
	tsfill, full
	bysort account (age_quarter) : carryforward branch pmjdy min_quarter max_quarter open_date, replace

	gsort account -age_quarter
	bysort account : carryforward branch pmjdy max_quarter min_quarter open_date, replace
	gen value_trans = value/transaction
	recode transaction value value_trans quarter_govt_assisted (.=0)
	
	drop if min_quarter>1 & pmjdy == 0 // dropped if minimum month is greater than 1
	keep if age_quarter<=max_quarter
	gen age_days = 90*age_quarter
	gen date = open_date + age_days
	format %td date
	gen quarter_date = quarter(date)
	gen quarter_year = year(date)*100+quarter(date)
	gen month_year = year(date)*100+month(date)
	gen month_date = month(date)
	gen year_date = year(date)
	encode branch, gen(branch_code)
	label var transaction "Transactions per Account"
	label var value "Transaction Value per Account"
	label var value_trans "Value per Transaction"
	
	bysort account (age_quarter) : gen quarter_govt_assisted_1 = quarter_govt_assisted[_n-1]
	recode quarter_govt_assisted_1 (.=0)
	gen t_t_1_govt = (quarter_govt_assisted_1==quarter_govt_assisted)
	replace t_t_1_govt=0 if quarter_govt_assisted==0
	global controls "t_t_1_govt"
	
	eststo P1: reghdfe transaction i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
	eststo P2: reghdfe value i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
	eststo P3: reghdfe value_trans i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
		outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear 

	foreach var in transaction value value_trans{
		putexcel A1=("Variabe") B1=("$gov PMJDY") C1=("Prob") D1=("$gov Savings") E1=("Prob") ///
			using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
		preserve
	//pmjdy
		su account if pmjdy == 1
		local N r(N)
		generate t5_pm = invttail(`N',0.05)
		gen b_pm=.
		gen se_pm=.
		forvalues i=2(1)8 {
		gen quarter_dummy`i'=(age_quarter==`i')
		}
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		//di `j' `k' `l'
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 1 & age_quarter <=`i', cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel A`j'=(`i') B`j'=(_b[quarter_dummy`i']) B`k'=("(`t_stat')") B`l'=(e(N)) C`j'=("`star'")  ///
		using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "F:\Projects\PMJDY data\Analysis\Result\combine_credit\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, PMJDY $cons $gov) append

		replace b_pm=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_pm=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_pm = b_pm-se_pm*t5_pm
		generate UB_pm = b_pm+se_pm*t5_pm
		
	//savings
		su account if pmjdy == 0
		local N r(N)
		generate t5_sv = invttail(`N',0.05)
		gen b_sv=.
		gen se_sv=.
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 0 & age_quarter <=`i', cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel D`j'=(_b[quarter_dummy`i']) D`k'=("(`t_stat')") D`l'=(e(N)) E`j'=("`star'")  ///
		using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "F:\Projects\PMJDY data\Analysis\Result\combine_credit\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, Savings $cons $gov) append
		replace b_sv=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_sv=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_sv = b_sv-se_sv*t5_sv
		generate UB_sv = b_sv+se_sv*t5_sv
		keep age_quarter b_pm b_sv LB_pm LB_sv UB_pm UB_sv
		duplicates drop
		sort age_quarter
		twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend( lab(1 "PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_pmjdy.png", as(png) replace
		twoway (connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend(lab(1 "Non-PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_savings.png", as(png) replace
		twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium)) ///
			(connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend( lab(1 "PMJDY") lab(3 "Non-PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr.png", as(png) replace
		tsset age_quarter
		var b_pm b_sv if age_quarter <=8, lag(1/2)
		vargranger
		restore
	}
}

****************************************************************************************************************************************
*** Table 10, 11 - Credit (Active deposits) ***
****************************************************************************************************************************************

****************************************************************************************************************************************
*** Table 10, 11 - Dedit (Active withdrawals) ***
****************************************************************************************************************************************

forvalues r =1/3{
	use "......\data_savings - version 2 - after demon - without sivarampally.dta", clear
	// dropping zero balance account
	//drop if zero == 1
//		keep if ACTIVE_WDL == 1 
		global cons "ACTIVE_WDL"
		replace amount = cond(ACTIVE_WDL==1,amount,0)
		
//		keep if pmjdy | SAL_savings
		
	if (`r' == 1){
		global gov "ALL"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 2){
		keep if govt_assisted_acc == 1
		global gov "GOV"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 3){
		keep if govt_assisted_acc == 0
		global gov "NO_GOV"
		global controls ""
		}

	** All accounts
	gen c = 1
	sort branch account age_month
	order branch account age_month
	collapse (sum) transaction = ACTIVE_WDL value=amount (mean) min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_quarter pmjdy)
	// filling the space
	tsset account age_quarter
	tsfill, full
	bysort account (age_quarter) : carryforward branch pmjdy min_quarter max_quarter open_date, replace

	gsort account -age_quarter
	bysort account : carryforward branch pmjdy max_quarter min_quarter open_date, replace
	gen value_trans = value/transaction
	recode transaction value value_trans quarter_govt_assisted (.=0)
	
	drop if min_quarter>1 & pmjdy == 0 // dropped if minimum month is greater than 1
	keep if age_quarter<=max_quarter
	gen age_days = 90*age_quarter
	gen date = open_date + age_days
	format %td date
	gen quarter_date = quarter(date)
	gen quarter_year = year(date)*100+quarter(date)
	gen month_year = year(date)*100+month(date)
	gen month_date = month(date)
	gen year_date = year(date)
	encode branch, gen(branch_code)
	label var transaction "Transactions per Account"
	label var value "Transaction Value per Account"
	label var value_trans "Value per Transaction"
	
	bysort account (age_quarter) : gen quarter_govt_assisted_1 = quarter_govt_assisted[_n-1]
	recode quarter_govt_assisted_1 (.=0)
	gen t_t_1_govt = (quarter_govt_assisted_1==quarter_govt_assisted)
	replace t_t_1_govt=0 if quarter_govt_assisted==0
	global controls "t_t_1_govt"
	
	eststo P1: reghdfe transaction i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
	eststo P2: reghdfe value i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
	eststo P3: reghdfe value_trans i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
		outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear 

	foreach var in transaction value value_trans{
		putexcel A1=("Variabe") B1=("$gov PMJDY") C1=("Prob") D1=("$gov Savings") E1=("Prob") ///
			using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
		preserve
	//pmjdy
		su account if pmjdy == 1
		local N r(N)
		generate t5_pm = invttail(`N',0.05)
		gen b_pm=.
		gen se_pm=.
		forvalues i=2(1)8 {
		gen quarter_dummy`i'=(age_quarter==`i')
		}
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		//di `j' `k' `l'
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 1 & age_quarter <=`i', cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel A`j'=(`i') B`j'=(_b[quarter_dummy`i']) B`k'=("(`t_stat')") B`l'=(e(N)) C`j'=("`star'")  ///
		using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "F:\Projects\PMJDY data\Analysis\Result\combine_debit\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, PMJDY $cons $gov) append

		replace b_pm=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_pm=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_pm = b_pm-se_pm*t5_pm
		generate UB_pm = b_pm+se_pm*t5_pm
		
	//savings
		su account if pmjdy == 0
		local N r(N)
		generate t5_sv = invttail(`N',0.05)
		gen b_sv=.
		gen se_sv=.
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 0 & age_quarter <=`i', cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel D`j'=(_b[quarter_dummy`i']) D`k'=("(`t_stat')") D`l'=(e(N)) E`j'=("`star'")  ///
		using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "F:\Projects\PMJDY data\Analysis\Result\combine_debit\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, Savings $cons $gov) append
		replace b_sv=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_sv=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_sv = b_sv-se_sv*t5_sv
		generate UB_sv = b_sv+se_sv*t5_sv
		keep age_quarter b_pm b_sv LB_pm LB_sv UB_pm UB_sv
		duplicates drop
		sort age_quarter
		twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend( lab(1 "PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_pmjdy.png", as(png) replace
		twoway (connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend(lab(1 "Non-PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_savings.png", as(png) replace
		twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium)) ///
			(connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend( lab(1 "PMJDY") lab(3 "Non-PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr.png", as(png) replace
		tsset age_quarter
		var b_pm b_sv if age_quarter <=8, lag(1/2)
		vargranger
		restore
	}
}

****************************************************************************************************************************************
*** Table 10, 11 - Dedit (Active withdrawals) ***
****************************************************************************************************************************************


****************************************************************************************************************************************
*** Table 12 - ATM ***
****************************************************************************************************************************************
forvalues r =1/3{
	use "......\data_savings - version 2 - after demon - without sivarampally.dta", clear
	// dropping zero balance account
	//drop if zero == 1
//		keep if ATM == 1 
		replace amount = cond(ATM==1,amount,0)
		global cons "ATM"

	if (`r' == 1){
		global gov "ALL"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 2){
		keep if govt_assisted_acc == 1
		global gov "GOV"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 3){
		keep if govt_assisted_acc == 0
		global gov "NO_GOV"
		global controls ""
		}

	** All accounts
	gen c = 1
	sort branch account age_month
	order branch account age_month
	collapse (sum) transaction = ATM value=amount (mean) min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_quarter pmjdy)
	// filling the space
	tsset account age_quarter
	tsfill, full
	bysort account (age_quarter) : carryforward branch pmjdy min_quarter max_quarter open_date, replace

	gsort account -age_quarter
	bysort account : carryforward branch pmjdy max_quarter min_quarter open_date, replace
	gen value_trans = value/transaction
	recode transaction value value_trans quarter_govt_assisted (.=0)
	
	drop if min_quarter>1 & pmjdy == 0 // dropped if minimum month is greater than 1
	keep if age_quarter<=max_quarter
	gen age_days = 90*age_quarter
	gen date = open_date + age_days
	format %td date
	gen quarter_date = quarter(date)
	gen quarter_year = year(date)*100+quarter(date)
	gen month_year = year(date)*100+month(date)
	gen month_date = month(date)
	gen year_date = year(date)
	encode branch, gen(branch_code)
	label var transaction "Transactions per Account"
	label var value "Transaction Value per Account"
	label var value_trans "Value per Transaction"
	
	bysort account (age_quarter) : gen quarter_govt_assisted_1 = quarter_govt_assisted[_n-1]
	recode quarter_govt_assisted_1 (.=0)
	gen t_t_1_govt = (quarter_govt_assisted_1==quarter_govt_assisted)
	replace t_t_1_govt=0 if quarter_govt_assisted==0
	global controls "t_t_1_govt"
	
	eststo P1: reghdfe transaction i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
	eststo P2: reghdfe value i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
	eststo P3: reghdfe value_trans i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
		outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear 

	foreach var in transaction value value_trans{
		putexcel A1=("Variabe") B1=("$gov PMJDY") C1=("Prob") D1=("$gov Savings") E1=("Prob") ///
			using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
		preserve
	//pmjdy
		su account if pmjdy == 1
		local N r(N)
		generate t5_pm = invttail(`N',0.05)
		gen b_pm=.
		gen se_pm=.
		forvalues i=2(1)8 {
		gen quarter_dummy`i'=(age_quarter==`i')
		}
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		//di `j' `k' `l'
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 1 & age_quarter <=`i', cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel A`j'=(`i') B`j'=(_b[quarter_dummy`i']) B`k'=("(`t_stat')") B`l'=(e(N)) C`j'=("`star'")  ///
		using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "F:\Projects\PMJDY data\Analysis\Result\atm\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, PMJDY $cons $gov) append

		replace b_pm=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_pm=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_pm = b_pm-se_pm*t5_pm
		generate UB_pm = b_pm+se_pm*t5_pm
		
	//savings
		su account if pmjdy == 0
		local N r(N)
		generate t5_sv = invttail(`N',0.05)
		gen b_sv=.
		gen se_sv=.
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 0 & age_quarter <=`i', cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel D`j'=(_b[quarter_dummy`i']) D`k'=("(`t_stat')") D`l'=(e(N)) E`j'=("`star'")  ///
		using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "F:\Projects\PMJDY data\Analysis\Result\atm\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, Savings $cons $gov) append
		replace b_sv=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_sv=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_sv = b_sv-se_sv*t5_sv
		generate UB_sv = b_sv+se_sv*t5_sv
		keep age_quarter b_pm b_sv LB_pm LB_sv UB_pm UB_sv
		duplicates drop
		sort age_quarter
		twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend( lab(1 "PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_pmjdy.png", as(png) replace
		twoway (connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend(lab(1 "Other Savings")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_savings.png", as(png) replace
		twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium)) ///
			(connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend( lab(1 "PMJDY") lab(3 "Other Savings")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr.png", as(png) replace
		tsset age_quarter
		var b_pm b_sv if age_quarter <=8, lag(1/2)
		vargranger
		restore
	}
}
****************************************************************************************************************************************
*** Table 12 - ATM ***
****************************************************************************************************************************************

****************************************************************************************************************************************
*** Table 12 - Cash ***
****************************************************************************************************************************************
forvalues r =1/3{
	use "......\data_savings - version 2 - after demon - without sivarampally.dta", clear
	// dropping zero balance account
	//drop if zero == 1
//		keep if CSH == 1 
		global cons "CSH"
		replace amount = cond(CSH==1,amount,0)

	if (`r' == 1){
		global gov "ALL"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 2){
		keep if govt_assisted_acc == 1
		global gov "GOV"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 3){
		keep if govt_assisted_acc == 0
		global gov "NO_GOV"
		global controls ""
		}

	** All accounts
	gen c = 1
	sort branch account age_month
	order branch account age_month
	collapse (sum) transaction = CSH value=amount (mean) min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_quarter pmjdy)
	// filling the space
	tsset account age_quarter
	tsfill, full
	bysort account (age_quarter) : carryforward branch pmjdy min_quarter max_quarter open_date, replace

	gsort account -age_quarter
	bysort account : carryforward branch pmjdy max_quarter min_quarter open_date, replace
	gen value_trans = value/transaction
	recode transaction value value_trans quarter_govt_assisted (.=0)
	
	drop if min_quarter>1 & pmjdy == 0 // dropped if minimum month is greater than 1
	keep if age_quarter<=max_quarter
	gen age_days = 90*age_quarter
	gen date = open_date + age_days
	format %td date
	gen quarter_date = quarter(date)
	gen quarter_year = year(date)*100+quarter(date)
	gen month_year = year(date)*100+month(date)
	gen month_date = month(date)
	gen year_date = year(date)
	encode branch, gen(branch_code)
	label var transaction "Transactions per Account"
	label var value "Transaction Value per Account"
	label var value_trans "Value per Transaction"
	
	bysort account (age_quarter) : gen quarter_govt_assisted_1 = quarter_govt_assisted[_n-1]
	recode quarter_govt_assisted_1 (.=0)
	gen t_t_1_govt = (quarter_govt_assisted_1==quarter_govt_assisted)
	replace t_t_1_govt=0 if quarter_govt_assisted==0
	global controls "t_t_1_govt"
	
	eststo P1: reghdfe transaction i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
	eststo P2: reghdfe value i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
	eststo P3: reghdfe value_trans i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
		outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear 


	foreach var in transaction value value_trans{
		putexcel A1=("Variabe") B1=("$gov PMJDY") C1=("Prob") D1=("$gov Savings") E1=("Prob") ///
			using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
		preserve
	//pmjdy
		su account if pmjdy == 1
		local N r(N)
		generate t5_pm = invttail(`N',0.05)
		gen b_pm=.
		gen se_pm=.
		forvalues i=2(1)8 {
		gen quarter_dummy`i'=(age_quarter==`i')
		}
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		//di `j' `k' `l'
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 1 & age_quarter <=`i', cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel A`j'=(`i') B`j'=(_b[quarter_dummy`i']) B`k'=("(`t_stat')") B`l'=(e(N)) C`j'=("`star'")  ///
		using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "F:\Projects\PMJDY data\Analysis\Result\csh\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, PMJDY $cons $gov) append

		replace b_pm=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_pm=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_pm = b_pm-se_pm*t5_pm
		generate UB_pm = b_pm+se_pm*t5_pm
		
	//savings
		su account if pmjdy == 0
		local N r(N)
		generate t5_sv = invttail(`N',0.05)
		gen b_sv=.
		gen se_sv=.
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 0 & age_quarter <=`i', cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel D`j'=(_b[quarter_dummy`i']) D`k'=("(`t_stat')") D`l'=(e(N)) E`j'=("`star'")  ///
		using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "F:\Projects\PMJDY data\Analysis\Result\csh\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, Savings $cons $gov) append
		replace b_sv=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_sv=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_sv = b_sv-se_sv*t5_sv
		generate UB_sv = b_sv+se_sv*t5_sv
		keep age_quarter b_pm b_sv LB_pm LB_sv UB_pm UB_sv
		duplicates drop
		sort age_quarter
		twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend( lab(1 "PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_pmjdy.png", as(png) replace
		twoway (connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend(lab(1 "Other Savings")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_savings.png", as(png) replace
		twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium)) ///
			(connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend( lab(1 "PMJDY") lab(3 "Other Savings")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr.png", as(png) replace
		tsset age_quarter
		var b_pm b_sv if age_quarter <=8, lag(1/2)
		vargranger
		restore
	}
}


***************************************************************************************************************************************
*** Table 12 - Cash ***
****************************************************************************************************************************************


****************************************************************************************************************************************
*** Table 8,9 ***
****************************************************************************************************************************************
*** Quarterly graphs, interaction and general Reg
***************************
forvalues r = 1/4{
	use "......\data_savings - version 2 - after demon - with zero balance v1 - edit - only Tamilnadu.dta", clear
	// dropping zero balance account
//	drop if zero == 1
//		keep if COMBINE == 1 
		global cons "COMBINE"
		replace amount = cond(COMBINE==1,amount,0)

	if (`r' == 1){
		global gov "ALL"
		global controls "quarter_govt_assisted"
		}

	else if (`r' == 2){
		keep if govt_assisted_acc == 1
		global gov "GOV"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 3){
		keep if govt_assisted_acc == 1
		drop if govt_init_trans == 1
		global gov "GOV_ex_GOV"
		global controls ""
		}
	else if (`r' == 4){
		keep if govt_assisted_acc == 0
		global gov "NO_GOV"
		global controls ""
		}

	** All accounts
	gen c = 1
	sort branch account age_month
	order branch account age_month
	collapse (sum) transaction = COMBINE value=amount (mean) min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_quarter pmjdy)
	// filling the space
	tsset account age_quarter
	tsfill, full
	bysort account (age_quarter) : carryforward branch pmjdy min_quarter max_quarter open_date, replace

	gsort account -age_quarter
	bysort account : carryforward branch pmjdy max_quarter min_quarter open_date, replace
	gen value_trans = value/transaction
	recode transaction value value_trans quarter_govt_assisted (.=0)
	
	drop if min_quarter>1 & pmjdy == 0 // dropped if minimum quarter is greater than 1
	keep if age_quarter<=max_quarter
	drop if age_quarter == 0	
	gen age_days = 90*age_quarter
	gen date = open_date + age_days
	format %td date
	gen quarter_date = quarter(date)
	gen quarter_year = year(date)*100+quarter(date)
	gen month_year = year(date)*100+month(date)
	gen month_date = month(date)
	gen year_date = year(date)
	encode branch, gen(branch_code)
	label var transaction "Transactions per Account"
	label var value "Transaction Value per Account"
	label var value_trans "Value per Transaction"

	bysort account (age_quarter) : gen quarter_govt_assisted_1 = quarter_govt_assisted[_n-1]
	recode quarter_govt_assisted_1 (.=0)
	gen t_t_1_govt = (quarter_govt_assisted_1==quarter_govt_assisted)
	replace t_t_1_govt=0 if quarter_govt_assisted==0
	global controls "t_t_1_govt"

//	gen du2_pm = (age_quarter == 2)&(pmjdy == 1)
//	gen age_2 = (age_quarter == 2)
//	reg transaction du2_pm age_2 pmjdy if age_quarter <=2
	
	eststo P1: reghdfe transaction i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
	outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label  nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear
	eststo P2: reghdfe value i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
	outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label  nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear
	eststo P3: reghdfe value_trans i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
		outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear 
	

	foreach var in transaction value value_trans{
		putexcel A1=("Variabe") B1=("$gov PMJDY") C1=("Prob") D1=("$gov Savings") E1=("Prob") ///
			using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
		preserve
	//pmjdy
		su account if pmjdy == 1
		local N r(N)
		generate t5_pm = invttail(`N',0.05)
		gen b_pm=.
		gen se_pm=.
		forvalues i=2(1)8 {
		gen quarter_dummy`i'=(age_quarter==`i')
		}
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		//di `j' `k' `l'
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 1 & age_quarter <=`i', cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel A`j'=(`i') B`j'=(_b[quarter_dummy`i']) B`k'=("(`t_stat')") B`l'=(e(N)) C`j'=("`star'")  ///
		using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "F:\Projects\PMJDY data\Analysis\Result\combine\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, PMJDY $cons $gov) append

		replace b_pm=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_pm=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_pm = b_pm-se_pm*t5_pm
		generate UB_pm = b_pm+se_pm*t5_pm
		
	//savings
		su account if pmjdy == 0
		local N r(N)
		generate t5_sv = invttail(`N',0.05)
		gen b_sv=.
		gen se_sv=.
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 0 & age_quarter <=`i', cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel D`j'=(_b[quarter_dummy`i']) D`k'=("(`t_stat')") D`l'=(e(N)) E`j'=("`star'")  ///
			using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "F:\Projects\PMJDY data\Analysis\Result\combine\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, Savings $cons $gov) append
		replace b_sv=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_sv=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_sv = b_sv-se_sv*t5_sv
		generate UB_sv = b_sv+se_sv*t5_sv
		keep age_quarter b_pm b_sv LB_pm LB_sv UB_pm UB_sv
		duplicates drop
		sort age_quarter
			twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium)), ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend( lab(1 "PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_pmjdy.png", as(png) replace
		twoway (connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)), ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend(lab(1 "non-PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_savings.png", as(png) replace
		twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium))  ///
			(connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)), ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend( lab(1 "PMJDY") lab(3 "non-PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr.png", as(png) replace
		tsset age_quarter
		var b_pm b_sv if age_quarter <=8, lag(1/2)
		vargranger
		restore
	}
}
****************************************************************************************************************************************
*** Table 8, 9 ***
****************************************************************************************************************************************


****************************************************************************************************************************************
*** Table 8,9 - try ***
****************************************************************************************************************************************
*** Quarterly graphs, interaction and general Reg
***************************
forvalues r = 1/4{
	use "......\data_savings - version 2 - after demon - only Tamilnadu.dta", clear
	// dropping zero balance account
//	drop if zero == 1
//		keep if COMBINE == 1 
		global cons "COMBINE"
		replace amount = cond(COMBINE==1,amount,0)

	if (`r' == 1){
		global gov "ALL"
		global controls "quarter_govt_assisted"
		}

	else if (`r' == 2){
		keep if govt_assisted_acc == 1
		global gov "GOV"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 3){
		keep if govt_assisted_acc == 1
		drop if govt_init_trans == 1
		global gov "GOV_ex_GOV"
		global controls ""
		}
	else if (`r' == 4){
		keep if govt_assisted_acc == 0
		global gov "NO_GOV"
		global controls ""
		}

	** All accounts
	gen c = 1
	sort branch account age_month
	order branch account age_month
	collapse (sum) transaction = COMBINE value=amount (mean) min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_quarter pmjdy)
	// filling the space
	tsset account age_quarter
	tsfill, full
	bysort account (age_quarter) : carryforward branch pmjdy min_quarter max_quarter open_date, replace

	gsort account -age_quarter
	bysort account : carryforward branch pmjdy max_quarter min_quarter open_date, replace
	gen value_trans = value/transaction
	recode transaction value value_trans quarter_govt_assisted (.=0)
	
	drop if min_quarter>1 & pmjdy == 0 // dropped if minimum quarter is greater than 1
	keep if age_quarter<=max_quarter
	drop if age_quarter == 0	
	gen age_days = 90*age_quarter
	gen date = open_date + age_days
	format %td date
	gen quarter_date = quarter(date)
	gen quarter_year = year(date)*100+quarter(date)
	gen month_year = year(date)*100+month(date)
	gen month_date = month(date)
	gen year_date = year(date)
	encode branch, gen(branch_code)
	label var transaction "Transactions per Account"
	label var value "Transaction Value per Account"
	label var value_trans "Value per Transaction"

	bysort account (age_quarter) : gen quarter_govt_assisted_1 = quarter_govt_assisted[_n-1]
	recode quarter_govt_assisted_1 (.=0)
	gen t_t_1_govt = (quarter_govt_assisted_1==quarter_govt_assisted)
	replace t_t_1_govt=0 if quarter_govt_assisted==0
	global controls "t_t_1_govt"

//	gen du2_pm = (age_quarter == 2)&(pmjdy == 1)
//	gen age_2 = (age_quarter == 2)
//	reg transaction du2_pm age_2 pmjdy if age_quarter <=2
	
	eststo P1: reghdfe transaction i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
	outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label  nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear
	eststo P2: reghdfe value i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
	outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label  nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear
	eststo P3: reghdfe value_trans i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
		outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear 
	

	foreach var in transaction value value_trans{
		putexcel A1=("Variabe") B1=("$gov PMJDY") C1=("Prob") D1=("$gov Savings") E1=("Prob") ///
			using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
		preserve
	//pmjdy
		su account if pmjdy == 1
		local N r(N)
		generate t5_pm = invttail(`N',0.05)
		gen b_pm=.
		gen se_pm=.
		forvalues i=2(1)8 {
		gen quarter_dummy`i'=(age_quarter==`i')
		sort account age_quarter
		by account: egen trancount`i'=sum(transaction) if age_quarter<`i'
		by account: egen tranaccount`i'=mean(trancount`i')
		gen tranaccountind`i'=cond(tranaccount`i'>0,1,0)
		drop trancount`i'		
		}
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		//di `j' `k' `l'
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 1 & age_quarter <=`i' & tranaccountind`i'==1, cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel A`j'=(`i') B`j'=(_b[quarter_dummy`i']) B`k'=("(`t_stat')") B`l'=(e(N)) C`j'=("`star'")  ///
		using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "F:\Projects\PMJDY data\Analysis\Result\combine\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, PMJDY $cons $gov) append

		replace b_pm=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_pm=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_pm = b_pm-se_pm*t5_pm
		generate UB_pm = b_pm+se_pm*t5_pm
		
	//savings
		su account if pmjdy == 0
		local N r(N)
		generate t5_sv = invttail(`N',0.05)
		gen b_sv=.
		gen se_sv=.
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 0 & age_quarter <=`i' & tranaccountind`i'==1, cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel D`j'=(_b[quarter_dummy`i']) D`k'=("(`t_stat')") D`l'=(e(N)) E`j'=("`star'")  ///
			using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "F:\Projects\PMJDY data\Analysis\Result\combine\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, Savings $cons $gov) append
		replace b_sv=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_sv=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_sv = b_sv-se_sv*t5_sv
		generate UB_sv = b_sv+se_sv*t5_sv
		keep age_quarter b_pm b_sv LB_pm LB_sv UB_pm UB_sv
		duplicates drop
		sort age_quarter
			twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium)), ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend( lab(1 "PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_pmjdy.png", as(png) replace
		twoway (connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)), ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend(lab(1 "non-PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_savings.png", as(png) replace
		twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium))  ///
			(connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)), ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)7, labsize(small)) xmtick(2(1)7, nolabels ticks) ///
			legend( lab(1 "PMJDY") lab(3 "non-PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr.png", as(png) replace
		tsset age_quarter
		var b_pm b_sv if age_quarter <=8, lag(1/2)
		vargranger
		restore
	}
}
****************************************************************************************************************************************
*** Table 8, 9 -  try ***
****************************************************************************************************************************************




*******************************************************************************************************************************************************
*** Table 13, 14 *** 
*******************************************************************************************************************************************************
*** use from balance_analysis_v2_control.dta ***

forvalues r = 1/3{
	use "......\data_savings - version 2 - after demon - without sivarampally.dta", clear
	// dropping zero balance account
	//drop if zero == 1
		global cons "BALANCE"

	if (`r' == 1){
		global gov "ALL"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 2){
		keep if govt_assisted_acc == 1
		global gov "GOV"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 3){
		keep if govt_assisted_acc == 0
		global gov "NO_GOV"
		global controls ""
		}
	** Quarter last balance
	bysort account age_month (date) : gen rank = _n
	bysort account age_month (date) : gen rank_max = _N
	keep if rank == rank_max

	gen c = 1
	sort branch account age_month
	order branch account age_month
//	collapse (sum) balance (mean) min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_quarter pmjdy)
	collapse (mean) balance  min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_quarter pmjdy)
	// filling the space
	tsset account age_quarter
	tsfill, full
	bysort account (age_quarter) : carryforward branch pmjdy min_quarter max_quarter open_date, replace
	//br if branch == ""
	gsort account -age_quarter
	bysort account : carryforward branch pmjdy max_quarter min_quarter open_date, replace
	recode quarter_govt_assisted (.=0)
	drop if min_quarter>1 & pmjdy == 0 // dropped if minimum month is greater than 1
	keep if age_quarter<=max_quarter
	gen age_days = 90*age_quarter
	gen date = open_date + age_days
	format %td date
	gen quarter_date = quarter(date)
	gen quarter_year = year(date)*100+quarter(date)
	gen month_year = year(date)*100+month(date)
	gen month_date = month(date)
	gen year_date = year(date)
	encode branch, gen(branch_code)

	gen ln_bal = log(1+balance)
	label var ln_bal "Log(1+Balance)"

	bysort account (age_quarter) : gen quarter_govt_assisted_1 = quarter_govt_assisted[_n-1]
	recode quarter_govt_assisted_1 (.=0)
	gen t_t_1_govt = (quarter_govt_assisted_1==quarter_govt_assisted)
	replace t_t_1_govt=0 if quarter_govt_assisted==0
	global controls "t_t_1_govt"

	bysort pmjdy: tabstat balance if age_quarter <=8, by(age_quarter) col(stat) statistics(mean p50)
	bysort pmjdy: tabstat ln_bal if age_quarter <=8, by(age_quarter) col(stat) statistics(mean p50)

	bysort pmjdy: tabstat balance if age_quarter == 1, col(stat) statistics(mean p10 p25 p50 p75 p90 sd)
	bysort pmjdy: tabstat balance if age_quarter == 2, col(stat) statistics(mean p10 p25 p50 p75 p90 sd)
	bysort pmjdy: tabstat balance if age_quarter == 3, col(stat) statistics(mean p10 p25 p50 p75 p90 sd)
	bysort pmjdy: tabstat balance if age_quarter == 4, col(stat) statistics(mean p10 p25 p50 p75 p90 sd)
	bysort pmjdy: tabstat balance if age_quarter == 5, col(stat) statistics(mean p10 p25 p50 p75 p90 sd)
	bysort pmjdy: tabstat balance if age_quarter == 6, col(stat) statistics(mean p10 p25 p50 p75 p90 sd)
	bysort pmjdy: tabstat balance if age_quarter == 7, col(stat) statistics(mean p10 p25 p50 p75 p90 sd)
	bysort pmjdy: tabstat balance if age_quarter == 8, col(stat) statistics(mean p10 p25 p50 p75 p90 sd)

	*** bysort pmjdy: tabstat balance if age_quarter == 8, col(stat) statistics(mean p10 p25 p50 p75 p90 sd) ***

	eststo P1: reghdfe ln_bal i.age_quarter##pmjdy $controls if age_quarter <=8, cluster(account) absorb(account  branch_code) keepsingletons
		outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label dec(4) nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear 

	foreach var in ln_bal{
		putexcel A1=("Variabe") B1=("$gov PMJDY") C1=("Prob") D1=("$gov Savings") E1=("Prob") ///
			using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
		
	//	gen pmjdy_age = age_quarter*pmjdy
	//pmjdy
		su account if pmjdy == 1
		local N r(N)
		generate t5_pm = invttail(`N',0.05)
		gen b_pm=.
		gen se_pm=.
		forvalues i=2(1)8 {
		gen quarter_dummy`i'=(age_quarter==`i')
		}
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		//di `j' `k' `l'
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 1 & age_quarter <=`i', cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel A`j'=(`i') B`j'=(_b[quarter_dummy`i']) B`k'=("(`t_stat')") B`l'=(e(N)) C`j'=("`star'")  ///
		using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "D:\PMJDY data\Analysis\Result\balance\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, PMJDY $cons $gov) append

		replace b_pm=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_pm=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_pm = b_pm-se_pm*t5_pm
		generate UB_pm = b_pm+se_pm*t5_pm
		
	//savings
		su account if pmjdy == 0
		local N r(N)
		generate t5_sv = invttail(`N',0.05)
		gen b_sv=.
		gen se_sv=.
		forvalues i=2(1)8 {
		di `i'
		local j=(3*`i'-2)
		local k=(`j'+1)
		local l=(`j'+2)
		reghdfe `var' quarter_dummy`i' $controls if pmjdy == 0 & age_quarter <=`i', cluster(account) absorb(account branch_code)
		local coeff = floor(_b[quarter_dummy`i']*10000)/10000
		di `coeff'
		local t_stat = floor((_b[quarter_dummy`i']/_se[quarter_dummy`i'])*10000)/10000
		di `t_stat'
		local p_val = 2*ttail(e(df_r),abs(_b[quarter_dummy`i']/_se[quarter_dummy`i']))
		di `p_val'
		if (`p_val' < 0.01) {
		local star "***"
		}
		else if (`p_val' < 0.05) {
		local star "**"
		}
		else if (`p_val' < 0.1) {
		local star "*"
		}
		else {
		local star ""
		}
		putexcel D`j'=(_b[quarter_dummy`i']) D`k'=("(`t_stat')") D`l'=(e(N)) E`j'=("`star'")  ///
		using "...\result_($cons)_qtr.xls", sheet(`var' $gov) modify
	//	outreg2 P1 using "D:\PMJDY data\Analysis\Result\balance\result_Combine_qtr(`var')_($gov).xls", ///
	//		label dec(4) nocons tstat paren keep( quarter_dummy`i' ) addtext(Cons, Savings $cons $gov) append
		replace b_sv=_b[quarter_dummy`i'] if age_quarter==`i'
		replace se_sv=_se[quarter_dummy`i'] if age_quarter==`i'
		}
		generate LB_sv = b_sv-se_sv*t5_sv
		generate UB_sv = b_sv+se_sv*t5_sv
		keep age_quarter b_pm b_sv LB_pm LB_sv UB_pm UB_sv
		duplicates drop
		/*gen quarters_on_the_job=qtrs_on_the_job*/
		sort age_quarter
			twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)8, labsize(small)) xmtick(2(1)8, nolabels ticks) ///
			legend( lab(1 "PMJDY")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_pmjdy.png", as(png) replace
		twoway (connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)),  ytitle("`var'") ///
			ytitle(, size(small)) yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)8, labsize(small)) xmtick(2(1)8, nolabels ticks) ///
			legend(lab(1 "Other Savings")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr_savings.png", as(png) replace
		twoway (connected b_pm age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(navy) mcolor(navy) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_pm UB_pm age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(navy) lpattern(dash) msize(medium)) ///
			(connected b_sv age_quarter if age_quarter<=8 & age_quarter >=2, sort lcolor(red) mcolor(red) msymbol(circle_hollow) cmissing(n)) ///
			(rcap LB_sv UB_sv age_quarter if age_quarter<=8 & age_quarter >=2, lcolor(red) lpattern(dash) msize(medium)), ///
			yline(0, lwidth(vthin) lpattern(dash) lcolor(teal)) ylabel(, labsize(small) angle(horizontal) nogrid) ///
			xtitle("Age (in quarters)") xtitle(, size(small) margin(medsmall)) xlabel(2(1)8, labsize(small)) xmtick(2(1)8, nolabels ticks) ///
			legend( lab(1 "PMJDY") lab(3 "Other Savings")) graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))
		graph export "...\($cons)(`var')($gov)_qtr.png", as(png) replace
		tsset age_quarter
		var b_pm b_sv if age_quarter <=8, lag(1/2)
		vargranger
		
	}
}

***************************************************************************************************************************************************
*** Table 13, 14 *** 
*******************************************************************************************************************************************************


*********************************************************************************************************************************************************
*** Table 15,16,17 ***
*********************************************************************************************************************************************************
*** ZIP3 results was taken for paper ***
*** use full data file ***
use "......\data_savings - version 2 - after demon - without sivarampally.dta"
 		global cons "COMBINE"
		global gov "ALL"
		global controls "govt_assistance_modified"

	** All accounts
	gen c = 1
	sort branch account age_month
	order branch account age_month
	collapse (sum) transaction=COMBINE transaction_dep=ACTIVE_DEP transaction_wdl=ACTIVE_WDL (mean) min_quarter max_quarter quarter_govt_assisted (first) open_date=open_date (first) balance, by(account branch AADHAAR_linked age_quarter pmjdy)
	// filling the space
	tsset account age_quarter
	tsfill, full
	bysort account (age_quarter) : carryforward branch pmjdy AADHAAR_linked min_quarter max_quarter open_date, replace

	gsort account -age_quarter
	bysort account : carryforward branch pmjdy AADHAAR_linked max_quarter min_quarter open_date, replace
//	gen value_trans = value/transaction
	//value value_trans
	recode transaction*  quarter_govt_assisted (.=0)
	
	drop if min_quarter>1 & pmjdy == 0 // dropped if minimum quarter is greater than 1
	keep if age_quarter<=max_quarter
	drop if age_quarter == 0	
	gen age_days = 90*age_quarter
	gen quarter_end = open_date + age_days
	gen quarter_begin = open_date + age_days -90
	gen quarter_mid = open_date + age_days - 45
	
	// new controls
	sort account age_quarter

	format %td quarter_end quarter_begin quarter_mid
/*	gen date = open_date + age_days
	format %td date
*/	
	gen quarter_of_year = quarter(quarter_mid)
	gen quarter_year = year(quarter_mid)*100+quarter(quarter_mid)
	encode branch, gen(branch_code)
	label var transaction "Transactions per Account"
	label var transaction_dep "Transactions per Account"
	label var transaction_wdl "Transactions per Account"

	bysort account (age_quarter) : gen quarter_govt_assisted_1 = quarter_govt_assisted[_n-1]
	recode quarter_govt_assisted_1 (.=0)
	gen t_t_1_govt = (quarter_govt_assisted_1==quarter_govt_assisted)
	replace t_t_1_govt=0 if quarter_govt_assisted!=1
	global controls "t_t_1_govt"

	gen age_quarter_pmjdy = age_quarter*pmjdy	
	
// Active all
//	areg transaction i.age_quarter $controls if pmjdy & age_quarter <=7, absorb(account) cluster(account)
	eststo P1: xtpoisson transaction age_quarter if pmjdy & age_quarter <=8, fe
	eststo P2: xtpoisson transaction age_quarter $controls if pmjdy & age_quarter <=8, fe 
	eststo P3: xtpoisson transaction i.age_quarter $controls if pmjdy & age_quarter <=8, fe
//	eststo P4: xtpoisson transaction age_quarter i.quarter_year if pmjdy & age_quarter <=7, fe
//	eststo P5: xtpoisson transaction age_quarter i.quarter_year $controls if pmjdy & age_quarter <=7, fe
	eststo P6: xtpoisson transaction age_quarter pmjdy age_quarter_pmjdy $controls if age_quarter <=8, fe
//	eststo P7: xtpoisson transaction age_quarter pmjdy age_quarter_pmjdy i.quarter_year $controls if age_quarter <=7, fe
//	eststo P4: areg transaction age_quarter pmjdy age_quarter_pmjdy $controls if age_quarter <=7, cluster(account) absorb(account) robust
	outreg2 [P*] using "...\result_poisson_qtr.xls", ///
		label nocons tstat paren addtext(Reg, XTPOISSON) replace
	eststo clear
	
// Active Credits
	eststo P1: xtpoisson transaction_dep age_quarter if pmjdy & age_quarter <=8,fe
	eststo P2: xtpoisson transaction_dep age_quarter $controls if pmjdy & age_quarter <=8, fe
	eststo P3: xtpoisson transaction_dep i.age_quarter $controls if pmjdy & age_quarter <=8, fe
//	eststo P4: xtpoisson transaction_dep age_quarter i.quarter_year if pmjdy & age_quarter <=7, fe
//	eststo P5: xtpoisson transaction_dep age_quarter i.quarter_year $controls if pmjdy & age_quarter <=7, fe
	eststo P6: xtpoisson transaction_dep age_quarter pmjdy age_quarter_pmjdy $controls if age_quarter <=8, fe
//	eststo P7: xtpoisson transaction_dep age_quarter pmjdy age_quarter_pmjdy i.quarter_year $controls if age_quarter <=7, fe
//	eststo P4: areg transaction_dep age_quarter pmjdy age_quarter_pmjdy $controls if age_quarter <=7, cluster(account) absorb(account) robust
	outreg2 [P*] using "...\result_COMBINE_poisson_credit_shrt.xls", ///
		label  nocons tstat paren addtext(Reg, XTPOISSON) replace
	eststo clear


// Active Debits	
	eststo P1: xtpoisson transaction_wdl age_quarter if pmjdy & age_quarter <=8,fe
	eststo P2: xtpoisson transaction_wdl age_quarter $controls if pmjdy & age_quarter <=8, fe
	eststo P3: xtpoisson transaction_wdl i.age_quarter $controls if pmjdy & age_quarter <=8, fe
//	eststo P4: xtpoisson transaction_wdl age_quarter i.quarter_year if pmjdy & age_quarter <=7, fe
//	eststo P5: xtpoisson transaction_wdl age_quarter i.quarter_year $controls if pmjdy & age_quarter <=7, fe
	eststo P6: xtpoisson transaction_wdl age_quarter pmjdy age_quarter_pmjdy $controls if age_quarter <=8, fe
//	eststo P7: xtpoisson transaction_wdl age_quarter pmjdy age_quarter_pmjdy i.quarter_year $controls if age_quarter <=7, fe
	outreg2 [P*] using "...\result_COMBINE_poisson_debit_shrt.xls", ///
		label nocons tstat paren addtext(Reg, XTPOISSON) replace
	eststo clear
	
/*	
	gen age_quarter_pmjdy = age_quarter*pmjdy
	global controls "quarter_govt_assisted"
	bysort account (age_quarter) : gen quarter_govt_assisted_1 = quarter_govt_assisted[_n-1]
	recode quarter_govt_assisted_1 (.=0)
	eststo P12: zip transaction age_quarter pmjdy age_quarter_pmjdy  $controls quarter_govt_assisted_1 if age_quarter <=7, inflate(pmjdy) vuong
	eststo P13: zip transaction_dep age_quarter pmjdy age_quarter_pmjdy  $controls quarter_govt_assisted_1 if age_quarter <=7, inflate(pmjdy) vuong
	eststo P14: zip transaction_wdl age_quarter pmjdy age_quarter_pmjdy  $controls quarter_govt_assisted_1 if age_quarter <=7, inflate(pmjdy) vuong
	outreg2 [P*] using "F:\Projects\PMJDY data\Analysis\Result\combine_dbt_forward\poisson\ZIP1.xls", ///
		label nocons tstat paren addtext(Reg, ZIP) replace
*/

	eststo P1: zip transaction age_quarter if age_quarter <=8, inflate(pmjdy) vuong
	eststo P2: zip transaction age_quarter $controls  if age_quarter <=8, inflate($controls pmjdy) vuong
	eststo P3: zip transaction age_quarter pmjdy age_quarter_pmjdy  $controls  if age_quarter <=8, inflate($controls pmjdy) vuong
	outreg2 [P*] using "...\ZIP3.xls", ///
		label nocons tstat paren addtext(Reg, ZIP) replace
	eststo clear

	eststo P1: zip transaction_dep age_quarter if age_quarter <=8, inflate(pmjdy) vuong
	eststo P2: zip transaction_dep age_quarter $controls  if age_quarter <=8, inflate($controls pmjdy) vuong
	eststo P3: zip transaction_dep age_quarter pmjdy age_quarter_pmjdy  $controls  if age_quarter <=8, inflate($controls pmjdy) vuong
	outreg2 [P*] using "...\ZIP4.xls", ///
		label nocons tstat paren addtext(Reg, ZIP) replace
	eststo clear
		
	eststo P1: zip transaction_wdl age_quarter if age_quarter <=8, inflate(pmjdy) vuong
	eststo P2: zip transaction_wdl age_quarter $controls  if age_quarter <=8, inflate($controls pmjdy) vuong
	eststo P3: zip transaction_wdl age_quarter pmjdy age_quarter_pmjdy  $controls  if age_quarter <=8, inflate($controls pmjdy) vuong
	outreg2 [P*] using "...\ZIP5.xls", ///
		label nocons tstat paren addtext(Reg, ZIP) replace
	eststo clear
		
	eststo P12: zip transaction age_quarter pmjdy age_quarter_pmjdy  $controls  if age_quarter <=8, inflate(pmjdy) vuong
	eststo P13: zip transaction_dep age_quarter pmjdy age_quarter_pmjdy  $controls if age_quarter <=8, inflate(pmjdy) vuong
	eststo P14: zip transaction_wdl age_quarter pmjdy age_quarter_pmjdy  $controls  if age_quarter <=8, inflate(pmjdy) vuong
	outreg2 [P*] using "...\ZIP2.xls", ///
		label nocons tstat paren addtext(Reg, ZIP) replace
/*	
	eststo P14: zip transaction_dep i.age_quarter $controls if pmjdy & age_quarter <=7, inflate(pmjdy) vuong
//	eststo P10: zip transaction_dep age_quarter i.quarter_year $controls if pmjdy & age_quarter <=7, inflate(AADHAAR_linked) vuong

	eststo P13: zip transaction_wdl age_quarter $controls if age_quarter <=7, inflate(pmjdy) vuong probit
	eststo P14: zip transaction_wdl i.age_quarter $controls if age_quarter <=7, inflate(pmjdy) vuong
//	eststo P10: zip transaction_wdl age_quarter i.quarter_year $controls if pmjdy & age_quarter <=7, inflate(AADHAAR_linked) vuong
	outreg2 [P*] using "F:\Projects\PMJDY data\Analysis\Result\combine_dbt_forward\poisson\ZIP.xls", ///
		label nocons tstat paren addtext(Reg, ZIP) append
	//	zip transaction_wdl age_quarter i.branch_code if pmjdy==0 & age_quarter <=7, inflate(account) vuong
*/
*******************************************************************************************************************************************************
*** Table 15,16,17 ***
*********************************************************************************************************************************************************

****************************************
*** table 5 ***
** no. of accounts, zero balance accs, no. of obs are all ok -- after dropping age_quarter>=8 ***
*** so age_quarter will be 1-7 only..no 8 ***
*** for average size of transactions ***
bysort account (date1) : egen mean_value = mean(amount)
preserve
keep account pmjdy mean_value COMBINE
duplicates drop
bysort pmjdy : su mean_value if COMBINE == 1, detail
su mean_value if COMBINE == 1, detail
bysort pmjdy : su mean_value, detail
su mean_value, detail
restore
*** table 5 ***
****************************************

****************************************
*** table  9  - from COMBINE_analysis_v2_control.do ***

forvalues r = 1/4{
	// use "F:\Projects\PMJDY data\Analysis\data.dta", clear
	// dropping zero balance account
//	drop if zero == 1
//		keep if COMBINE == 1 
		global cons "COMBINE"
		replace amount = cond(COMBINE==1,amount,0)

	if (`r' == 1){
		global gov "ALL"
		global controls "quarter_govt_assisted"
		}

	else if (`r' == 2){
		keep if govt_assisted_acc == 1
		global gov "GOV"
		global controls "quarter_govt_assisted"
		}
	else if (`r' == 3){
		keep if govt_assisted_acc == 1
		drop if govt_init_trans == 1
		global gov "GOV_ex_GOV"
		global controls ""
		}
	else if (`r' == 4){
		keep if govt_assisted_acc == 0
		global gov "NO_GOV"
		global controls ""
		}

	** All accounts
	gen c = 1
	sort branch account age_month
	order branch account age_month
	collapse (sum) transaction = COMBINE value=amount (mean) min_quarter max_quarter quarter_govt_assisted (first) open_date, by(account branch age_quarter pmjdy)
	// filling the space
	tsset account age_quarter
	tsfill, full
	bysort account (age_quarter) : carryforward branch pmjdy min_quarter max_quarter open_date, replace

	gsort account -age_quarter
	bysort account : carryforward branch pmjdy max_quarter min_quarter open_date, replace
	gen value_trans = value/transaction
	recode transaction value value_trans quarter_govt_assisted (.=0)
	
	drop if min_quarter>1 & pmjdy == 0 // dropped if minimum quarter is greater than 1
	keep if age_quarter<=max_quarter
	drop if age_quarter == 0	
	gen age_days = 90*age_quarter
	gen date = open_date + age_days
	format %td date
	gen quarter_date = quarter(date)
	gen quarter_year = year(date)*100+quarter(date)
	gen month_year = year(date)*100+month(date)
	gen month_date = month(date)
	gen year_date = year(date)
	encode branch, gen(branch_code)
	label var transaction "Transactions per Account"
	label var value "Transaction Value per Account"
	label var value_trans "Value per Transaction"

	bysort account (age_quarter) : gen quarter_govt_assisted_1 = quarter_govt_assisted[_n-1]
	recode quarter_govt_assisted_1 (.=0)
	gen t_t_1_govt = (quarter_govt_assisted_1==quarter_govt_assisted)
	replace t_t_1_govt=0 if quarter_govt_assisted==0
	global controls "t_t_1_govt"

//	gen du2_pm = (age_quarter == 2)&(pmjdy == 1)
//	gen age_2 = (age_quarter == 2)
//	reg transaction du2_pm age_2 pmjdy if age_quarter <=2
	
	eststo P1: reghdfe transaction i.age_quarter##pmjdy $controls if age_quarter <=7, cluster(account) absorb(account  branch_code) keepsingletons
	outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label  nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear
	eststo P2: reghdfe value i.age_quarter##pmjdy $controls if age_quarter <=7, cluster(account) absorb(account  branch_code) keepsingletons
	outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label  nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear
	eststo P3: reghdfe value_trans i.age_quarter##pmjdy $controls if age_quarter <=7, cluster(account) absorb(account  branch_code) keepsingletons
		outreg2 [P*] using "...\result_($cons)_intr.xls", ///
			label nocons tstat paren addtext(Cons, PMJDY $cons $gov) append
	eststo clear 
*****************************************************************************************
*** table  9  - from COMBINE_analysis_v2_control.do ***
*****************************************************************************************

*******************************************************************************************
*** Figure 2 - Kaplan Meier survival estimates ***
*******************************************************************************************
drop if age_quarter>8
//	drop if min_quarter > 1 & pmjdy == 0
	sort account age journal_no
	bys account: egen passive_only=max(COMBINE)
	g inactive=0
	replace inactive=1 if zero==1|passive_only==0
	keep if COMBINE==1|inactive==1
	sort account date journal_no
	keep if account!=account[_n-1]
	gen died = (inactive == 0) // this says if the account becomes active
	drop if pmjdy == 0 & open_date_s2 <= mdy(06,16,2013)
//	drop if pmjdy == 0 & acct_open_v2 <= mdy(06,16,2013)
//	gen survival_time = cond(died,age,630)
	gen survival_time = cond(died,age,730) // for pmjdy and savings (we need a fix here, as there will be zero balance account opened later and by 31st october may be less than 630 days)
//	replace survival_time = 630 if survival_time > 630 & pmjdy == 1
	
	stset survival_time, failure(died)
	sts graph if pmjdy, na risktable
	sts list if pmjdy, na // other way is 	sts graph , by(pmjdy) cumh
	sts list if !pmjdy, na // other way is 	sts graph , by(pmjdy) cumh

	sts graph if pmjdy, risktable
	sts graph if pmjdy, haz
	sts graph if pmjdy, failure
	sts graph if !pmjdy, na risktable
	sts graph if !pmjdy, risktable
	sts graph , by(pmjdy)  xlabel(0 200 400 600 730)  ///
		plot1opts(lpattern(l) lcolor(black)) ///
		plot2opts(lpattern(--) lcolor(black)) ///
		legend(label(2 "PMJDY") label(1 "non-PMJDY")) 
	stset, clear
*******************************************************************************************
*** Figure 2 - Kaplan Meier survival estimates ***
*******************************************************************************************
