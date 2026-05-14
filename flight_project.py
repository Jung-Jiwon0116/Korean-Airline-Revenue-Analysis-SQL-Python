import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sqlalchemy import create_engine

# Database Connection

engine = create_engine('mysql+pymysql://root:12345678@localhost:3306/Flight_Project')

# Global Plotting Settings
sns.set_theme(style="whitegrid")
plt.rcParams['figure.dpi'] = 150 


def run_flight_analytics():
    """
    Performs comprehensive airline data analysis including Revenue, 
    Load Factor, and Fuel Efficiency, and visualizes the results in a multi-graph dashboard.
    """
    
    # Data Extraction
    
    # Query 1: Operational Efficiency (Load Factor & Fuel per Pax)
    query_efficiency = """
    SELECT 
        B.Day, 
        A.model_name AS Aircraft_Model,
        COUNT(B.booking_id) AS total_passengers,
        A.total_seats,
        ROUND((COUNT(B.booking_id) / A.total_seats) * 100, 1) AS load_factor,
        ROUND(A.fuel / COUNT(B.booking_id), 2) AS fuel_per_pax
    FROM Bookings B
    JOIN Aircraft A ON B.Aircraft_Model = A.model_name
    GROUP BY B.Day, A.model_name, A.total_seats, A.fuel;
    """
    
    # Query 2: Revenue Contribution by Seat Class
    query_revenue = """
    SELECT 
        B.Day,
        B.Seat_Class,
        SUM(CASE WHEN B.Seat_Class = 'Prestige' THEN A.price_prestige ELSE A.price_economy END) AS revenue_krw
    FROM Bookings B
    JOIN Aircraft A ON B.Aircraft_Model = A.model_name
    GROUP BY B.Day, B.Seat_Class;
    """

    # Convert to DataFrames
    df_eff = pd.read_sql(query_efficiency, engine)
    df_rev = pd.read_sql(query_revenue, engine)

    # Standardize Day column for proper sorting
    # Note: If your DB stores '월', '화', it's better to map them to English for global viewers
    day_map = {'Mon': 'Mon', 'Tue': 'Tue', 'Wed': 'Wed', 'Thu': 'Thu', 'Fri': 'Fri', 'Sat': 'Sat', 'Sun': 'Sun'}
    df_eff['Day'] = df_eff['Day'].map(day_map)
    df_rev['Day'] = df_rev['Day'].map(day_map)
    
    days_order = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    df_eff['Day'] = pd.Categorical(df_eff['Day'], categories=days_order, ordered=True)
    df_rev['Day'] = pd.Categorical(df_rev['Day'], categories=days_order, ordered=True)

    # Visualization
    fig, axes = plt.subplots(2, 2, figsize=(20, 14))
    fig.suptitle('Airline Route Performance & Revenue Analytics Dashboard', fontsize=24, fontweight='bold')

    # Graph 1: Load Factor Trends
    sns.lineplot(x='Day', y='load_factor', hue='Aircraft_Model', data=df_eff, marker='o', ax=axes[0, 0], palette='viridis')
    axes[0, 0].set_title('Passenger Load Factor Trends (%)', fontsize=16)
    axes[0, 0].set_ylabel('Load Factor (%)')

    # Graph 2: Revenue Stacked Bar
    rev_pivot = df_rev.pivot(index='Day', columns='Seat_Class', values='revenue_krw')
    rev_pivot.plot(kind='bar', stacked=True, ax=axes[0, 1], color=['#2ecc71', '#e67e22'])
    axes[0, 1].set_title('Revenue Contribution by Seat Class', fontsize=16)
    axes[0, 1].set_ylabel('Revenue (KRW)')
    axes[0, 1].legend(title='Seat Class')

    # Graph 3: Fuel Efficiency (Lower is better)
    sns.barplot(x='Aircraft_Model', y='fuel_per_pax', data=df_eff, ax=axes[1, 0], palette='magma')
    axes[1, 0].set_title('Fuel Consumption per Passenger (Efficiency)', fontsize=16)
    axes[1, 0].set_ylabel('Fuel / Pax')

    # Graph 4: Passenger Distribution
    sns.barplot(x='Day', y='total_passengers', data=df_eff, estimator=sum, ax=axes[1, 1], palette='Blues_d', ci=None)
    axes[1, 1].set_title('Daily Total Passenger Volume', fontsize=16)
    axes[1, 1].set_ylabel('Total Passengers')

    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    
    # Export for GitHub Documentation
    plt.savefig('airline_analytics_dashboard.png', dpi=300)
    print("Analysis Complete. Dashboard saved as 'airline_analytics_dashboard.png'")
    plt.show()

if __name__ == "__main__":
    run_flight_analytics()