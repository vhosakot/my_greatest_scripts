#!/usr/bin/python

# script to calculate compound interest
#
# usage: ./compound_interest.py -h

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("investment", type=float)
parser.add_argument("profit_per_week", type=float)
args = parser.parse_args()

# initial investment
investment = args.investment

# profit percentage per week (a year has ~50 weeks)
profit_percentage_per_week = ( 100 * args.profit_per_week ) / args.investment

for d in range( 0, (1 * 50) ):
    print "============ week", d+1, "============\n"
    print "investment before profit =", investment
    profit = float(profit_percentage_per_week / 100.00) * float(investment)
    print "           weekly profit =", float(profit)
    investment = float(investment) + float(profit)
    print " investment after profit =", investment, "\n"

print "annual profit percentage =", ( ( float(investment) - float(args.investment) ) * 100 ) / args.investment, "%\n"
