#!/usr/bin/python

# script to calculate stop loss and stop price
#
# usage: ./stop_loss.py -h

import argparse

parser = argparse.ArgumentParser()
parser.add_argument("investment", type=float)
parser.add_argument("price_per_stock", type=float)
parser.add_argument("--loss_percent", type=float, default=20)
args = parser.parse_args()

loss_amount = float(args.loss_percent / 100.00) * float(args.investment)
investment_after_loss = float(args.investment) - float(loss_amount)
number_of_stocks_purchased = int(args.investment / args.price_per_stock)

print "\ninvestment                 = ", args.investment
print "price per stock            = ", args.price_per_stock
print "number of stocks purchased = ", number_of_stocks_purchased, "\n"

print "loss precent          = ", str(args.loss_percent) + "%"
print "loss amount           = ", loss_amount
print "investment after loss = ", investment_after_loss

stop_price = float(investment_after_loss) / float(number_of_stocks_purchased)
print "stop price            = ", stop_price

print "\nsell all", number_of_stocks_purchased, \
      "stocks each at \"stop price\"", stop_price, \
      "after", str(args.loss_percent) + "% loss (" + str(loss_amount) +") to make", \
      investment_after_loss, "\n"

print number_of_stocks_purchased, "x", stop_price, " = ", investment_after_loss, "\n"
