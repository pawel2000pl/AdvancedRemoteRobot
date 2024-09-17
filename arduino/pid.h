
class Pid
{
    public:

        Pid(float Kp, float Ti, float Td, float initialValue = 0, float initIntegral = 0)
        {
            kp = Kp;
            ti = Ti;
            td = Td;
            ep = initialValue;
            integral = initIntegral;
        }

        float process(float e, float dt = 1)
        {
            integral += (e+ep)*dt*0.5;
            float differential = (e-ep)/dt;
            float u = kp*(e + integral/ti + td*differential);
            ep = e;
            return u;
        }

        float processValues(float destValue, float currentValue, float dt = 1)
        {
            return process(destValue-currentValue, dt);
        }

        Pid& setValue(float newValue = 0)
        {
            ep = newValue;
            return *this;
        }

        Pid& setIntegral(float newValue = 0)
        {
            integral = newValue;
            return *this;
        }

    private:
        float kp, ti, td;
        float integral;
        float ep;

};