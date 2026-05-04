import 'package:flutter/material.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/date_filter_bar.dart';
import 'accountant_summary_dummy.dart';

class AccountantSummaryScreen extends StatelessWidget {
  const AccountantSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Financial Summary',
      filters: DateFilterBar(
        onFilterChanged: (filter) {
          debugPrint('Selected Filter: $filter');
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Overview'),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 800
                    ? 3
                    : (constraints.maxWidth > 500 ? 2 : 1);

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: crossAxisCount == 1 ? 3 : 2.5,
                  children: [
                    SummaryCard(
                      title: 'Total Revenue',
                      value:
                          AccountantSummaryDummy.summary['totalRevenue'] ?? '0',
                      icon: Icons.account_balance_wallet,
                      iconColor: Colors.green,
                    ),
                    SummaryCard(
                      title: 'Total Expenses',
                      value: AccountantSummaryDummy.summary['totalExpenses'] ??
                          '0',
                      icon: Icons.money_off,
                      iconColor: Colors.red,
                    ),
                    SummaryCard(
                      title: 'Net Profit',
                      value: AccountantSummaryDummy.summary['netProfit'] ?? '0',
                      icon: Icons.trending_up,
                      iconColor: Colors.blue,
                    ),
                    SummaryCard(
                      title: 'Cash in Hand',
                      value:
                          AccountantSummaryDummy.summary['cashInHand'] ?? '0',
                      icon: Icons.payments,
                      iconColor: Colors.teal,
                    ),
                    SummaryCard(
                      title: 'Bank Balance',
                      value:
                          AccountantSummaryDummy.summary['bankBalance'] ?? '0',
                      icon: Icons.account_balance,
                      iconColor: Colors.indigo,
                    ),
                    SummaryCard(
                      title: 'Unpaid Invoices',
                      value: AccountantSummaryDummy.summary['unpaidInvoices'] ??
                          '0',
                      icon: Icons.receipt,
                      iconColor: Colors.orange,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildRecentTransactions()),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildExpenseBreakdown()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildRecentTransactions(),
                      const SizedBox(height: 24),
                      _buildExpenseBreakdown(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Transactions'),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AccountantSummaryDummy.recentTransactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = AccountantSummaryDummy.recentTransactions[index];
              final isCredit = tx['type'] == 'Credit';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isCredit ? Colors.green.shade50 : Colors.red.shade50,
                  child: Icon(
                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isCredit ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(tx['description'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(tx['date'] ?? '',
                    style: const TextStyle(fontSize: 12)),
                trailing: Text(
                  '${isCredit ? '+' : '-'} ${tx['amount'] ?? ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Expense Breakdown'),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AccountantSummaryDummy.expenseBreakdown.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final exp = AccountantSummaryDummy.expenseBreakdown[index];

              return ListTile(
                title: Text(exp['category'] ?? '',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: LinearProgressIndicator(
                    value: (exp['percentage'] ?? 0) / 100,
                    backgroundColor: Colors.grey.shade100,
                    color: Colors.blueAccent,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                trailing: Text(exp['amount'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              );
            },
          ),
        ),
      ],
    );
  }
}
