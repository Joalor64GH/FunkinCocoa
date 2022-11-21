package;

/**
	It really is nerfed by the way.
	It gives A LOT more accuracy now.
**/
class NerfedEtterna
{
	public static function calculate(maxms:Float, ts:Float):Float
	{
		var max_points:Float = 1.0;
		var miss_weight:Float = 0.25;
		var ridic:Float = Math.pow(11 * ts, 1.415);
		var max_boo_weight:Float = 130 * ts;
		var ts_pow:Float = 0.825;
		var zero:Float = 65 * (Math.pow(ts, ts_pow));
		var dev:Float = 22.7 * (Math.pow(ts, ts_pow));

		if (maxms <= ridic) // anything below this (judge scaled) threshold is counted as full pts
			return max_points;
		else if (maxms <= zero) // ma/pa region, exponential
			return max_points * erf((zero - maxms) / dev);
		else if (maxms <= max_boo_weight) // cb region, linear
			return (maxms - zero) * miss_weight / (max_boo_weight - zero);

		return miss_weight;
	}

	// erf constants
	public static var a1:Float = 0.254829592;
	public static var a2:Float = -0.284496736;
	public static var a3:Float = 1.421413741;
	public static var a4:Float = -1.453152027;
	public static var a5:Float = 1.061405429;
	public static var p:Float = 0.3275911;

	public static function erf(x:Float):Float
	{
		// Save the sign of x
		var sign = 1;
		if (x < 0)
			sign = -1;
		x = Math.abs(x);

		// A&S formula 7.1.26
		var t = 1.0 / (1.0 + p * x);
		var y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x);

		return sign * y;
	}

	public static function nerf(wife:Float):Float
	{
		if (wife < 0.25)
			wife = 0.25;

		return wife;
	}
}
