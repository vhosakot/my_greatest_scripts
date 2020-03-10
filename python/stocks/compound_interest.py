#!/usr/bin/python

# script to calculate compound interest
#
# usage: ./compound_interest.py -h

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("investment", type=int)
parser.add_argument("profit_per_week", type=int)
args = parser.parse_args()

# initial investment
investment = args.investment

# margin loan percentage
margin_loan_percentage = 1.0

# profit percentage per week (a year has ~50 weeks)
profit_percentage_per_week = ( 100.0 * args.profit_per_week ) / float(args.investment)

print "\n initial capital =", args.investment
print " profit per week =", args.profit_per_week
print " profit % per week =", profit_percentage_per_week, "\n"

ytd_short_term_gain_tax = 0.0
ytd_profit = 0.0

def get_margin_call_drop_precentage(investment, margin_loan_amount):
    margin_req_precentage = 0.3
    # margin_req_precentage = 0.4
    total_investment = float(investment) + float(margin_loan_amount)

    for i in range(1, 99):
        value_after_drop = float(total_investment) - float(total_investment * (i  / 100.0))
        non_margin_amount_after_drop = float(value_after_drop) - float(margin_loan_amount)
        print "  after", str(i) + "% drop from", str(total_investment) + ":"
        print "    value of stock =", value_after_drop
        print "    margin loan =", margin_loan_amount
        print "    my investment =", str(round(non_margin_amount_after_drop, 2)) + " (" + \
            str(round(((100.0 * non_margin_amount_after_drop) / value_after_drop), 2)) + \
            "% of stock value", str(round(value_after_drop, 2)) + ")"
        if float(non_margin_amount_after_drop) <= float(value_after_drop) * float(margin_req_precentage):
            print "    margin requirement =", str(margin_req_precentage * 100.00) + "%"
            return i

for d in range(0, 50):
    print "============ week", d+1, "============\n"

    margin_loan_amount = float(margin_loan_percentage) * float(investment)
    print "", str(margin_loan_percentage * 100.0) + \
        "% margin loan for", float(investment), "capital =", float(margin_loan_amount)

    # margin loan has 10% annual interest
    daily_margin_loan_interest = (0.1 * float(margin_loan_percentage * investment)) / 250.0
    print " daily interest for", float(margin_loan_percentage * investment), "margin loan =", \
        float(daily_margin_loan_interest)

    print " investment before profit =", float(investment), "+", float(margin_loan_amount), \
        "=", float(investment) + float(margin_loan_amount)

    # find out how much stock can drop without margin call
    if margin_loan_amount > 0:
        margin_call_drop_precentage = get_margin_call_drop_precentage(investment, margin_loan_amount)
        print " margin call if stock drops", str(margin_call_drop_precentage) + "% or more"

    investment = float(investment) + float(margin_loan_percentage * investment)

    profit = float(profit_percentage_per_week / 100.00) * float(investment)

    print "", str(profit_percentage_per_week) + "% weekly profit with", \
        float(investment), "investment =", float(profit)

    # short-term capital gains tax is ~50% (33% federal tax + 12% MA tax)
    ytd_short_term_gain_tax  = ytd_short_term_gain_tax + (profit / 2.0)
    ytd_profit = ytd_profit + profit

    # daily margin loan interest paid back to broker is not profit
    profit = profit - daily_margin_loan_interest

    # pay back margin loan amount to broker
    investment = investment - margin_loan_amount

    print " profit after paying", float(daily_margin_loan_interest), "margin loan interest for", \
        float(margin_loan_amount), "margin loan =", float(profit)

    investment = float(investment) + float(profit)
    print " capital after profit for re-investment=", float(investment)

    print " total profit from", args.investment, "initial capital =", \
        float(investment) - args.investment, "\n"

print "total YTD annual profit =", float(ytd_profit)
print "total YTD short-term capital gains tax from all sales =", float(ytd_short_term_gain_tax)

# short-term capital gains tax is ~50% (33% federal tax + 12% MA tax)
print "short-term capital gains tax for", float(investment) - args.investment, \
    "total annual profit =", (float(investment) - args.investment) / 2.0

print "short-term capital gains tax for", float(ytd_profit), \
    "total YTD annual profit =", float(ytd_profit / 2.0)

print "total annual profit after tax =", (float(investment) - args.investment) / 2.0

print "annual profit percentage before tax =", \
    str(float((investment - args.investment) * 100.0) / args.investment) + "%"

print "annual profit percentage after tax =", \
    str(float(((investment - args.investment) / 2.0) * 100.0) / float(args.investment)) + "%\n"
